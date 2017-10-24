#!/opt/chefdk/embedded/bin/ruby

require 'git'
require 'set'
require 'find'
require 'uri'
require 'logger'
require 'optparse'
require 'chef'

# A dummy logger
@LOG = Logger.new(STDOUT)
@LOG.level = Logger::INFO

def parse_options
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: new_release.rb [options]'

    opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
      @LOG = @LOG.level = Logger::DEBUG if v
    end
    opts.on('-r#.#[.#]', '--release=#.#[.#]', 'Release version') do |release|
      options[:release] = Gem::Version.new(release)
    end
    opts.on('-h', '--[no-]hot-fix', 'Creating a new micro version') do |hot_fix|
      options[:hot_fix] = hot_fix
    end
    opts.on('--repos=GIT_REPO[,GIT_REPO...]', 'Repos to modify') do |repos|
      options[:repos] = repos.split(',').map do |r|
        repo = URI.extract(r)
        repo = r if repo.length != 1 && File::exist?(r)
        raise ArgumentError.new("Repo (#{r}) could not be parsed") if \
          repo.nil? or repo.length < 1
        repo
      end
    end
  end.parse!

  # we need to either have a release or a hot fix
  raise ArgumentError.new('One needs to either a new release or hot fix') \
    if !options[:release] && !options[:hot_fix]

  options[:repos] = ['https://github.com/bloomberg/chef-bach'] unless options[:repos]
  @LOG.debug("Running for repos #{options[:repos]}")

  options
end

# Update metadata files looking for cookbooks and setting their required
# version to the version requested. We need to know the metadata file path to
# modify
# Arguments: git_repo: the enclosing git repository to update
#            metadata_path: file path to the metadata.*
#            version: the version to set on each cookbook
#            cookbooks: an array of cookbooks to set the version for
# Returns:   cookbook name of metadata touched
def rewrite_dependencies(git_repo, metadata_path, version, cookbooks)
  metadata = Chef::Cookbook::Metadata.new
  metadata.from_file(File::join(git_repo.dir.to_s, metadata_path))
  metahash = metadata.to_hash

  metahash['dependencies'].keys.each do |cb|
    metahash['dependencies'][cb] = "=#{version}" if cookbooks.include?(cb)
  end

  # remove Ruby metadata files as we will only write JSON
  if File::extname(metadata_path) == ".rb"
    old_metadata_path = metadata_path
    metadata_path = File::join(File::dirname(metadata_path), 'metadata.json')
    @LOG.debug{ "Re-writing #{old_metadata_path} as JSON at #{metadata_path}" }
    git_repo.lib.mv(old_metadata_path, metadata_path)
  end

  File.open(File::join(git_repo.dir.to_s, metadata_path), 'w') do |md_file|
    md_file.write(JSON.pretty_generate(metadata.to_hash))
    md_file.flush
    git_repo.add(metadata_path)
  end
  metadata.name
end

# Search a path for metadata.rb/metadata.json
# If the path has a directory called cookbooks assume this is an uber cookbook
# and recurse past the initial path even if it contains a metadata; otherwise
# will not recurse past any directory contining a metadata file
# Arguments: Git repo to search under
# Returns:   A hash of metadata paths to cookbook names
def find_metadatas(repo)
  metadatas = Hash[
    repo.ls_files.select do |m,d|
      m.end_with?('metadata.rb') or m.end_with?('metadata.json')
    end.keys.map do |m|
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file(File::join(repo.dir.to_s, m))
      [m, metadata.name]
    end
  ]
end

# Arguments: git_repo - A Git::Base repo
# Returns: The latest revision created as two strings from Gem::Version
#          Branch is the first version (excludes 'release-')
#          Tag is the second version (excludes 'v')
def latest_revision(git_repo)
  # we do not support "prelease" strings today numbers only
  branch_regex = Regexp.new('^release-(\d{1,}.)*(\d{1,}){1,}$')
  tag_regex = Regexp.new('^v(\d{1,}.)*(\d{1,}){1,}$')

  rel_branches = git_repo.branches.select{ |b| branch_regex.match(b.name) }
  rel_tags = git_repo.tags.select{ |t| tag_regex.match(t.name) }

  branch_vers = rel_branches.map{ |b|
    Gem::Version.new(b.name.split('release-').last) }.sort
  branch_vers = ['0.0'] if branch_vers.length < 1
  tag_vers = rel_tags.map{ |t|
    Gem::Version.new(t.name.split('v').last) }.sort
  tag_vers = ['0.0'] if tag_vers.length < 1

  [branch_vers.last.to_s, tag_vers.last.to_s]
end

## Main
if __FILE__ == $PROGRAM_NAME
  options = parse_options

  cookbooks = Set.new()
  # find all cookbooks we need to update
  dir = Dir.mktmpdir
  #XXX Dir.mktmpdir do |dir|
  @LOG.info{ "Checking out into directory #{dir}" }

  options[:repos].each do |repo|
    g = Git.clone(repo, File::join(dir, File::basename(repo)), :log => nil)
    metadatas = find_metadatas(g)
    metadatas.each{ |md, cb| cookbooks << cb }
  end

  options[:repos].each do |repo|
    g = Git.open(File::join(dir, File::basename(repo)), :log => nil)
    branch_ver, tag_ver = latest_revision(g)

    # we are creating a new release
    if !options[:hot_fix]
      # go from e.g. 2.0.4 -> 2.1
      branch_ver = Gem::Version.new(tag_ver).bump.to_s
      tag_ver = branch_ver + ".0"
      g.branch(Gem::Version.new(branch_ver).bump.to_s).checkout
    else
      # we re-use a branch for a hot fix
      tag_ver = tag_ver.to_s.succ
      g.branch(branch_ver).checkout
    end

    @LOG.debug{ "Updating to version #{tag_ver} in branch #{branch_ver}" }
    metadatas = find_metadatas(g)
    metadatas.keys.each do |md_file|
      rewrite_dependencies(g, md_file, tag_ver, cookbooks)
    end

    g.commit("Commit for release #{tag_ver}")
    g.add_tag('v' + tag_ver, {:message => "Tag release v#{tag_ver}"})
  end
end
