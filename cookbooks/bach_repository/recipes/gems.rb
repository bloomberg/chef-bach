#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
include_recipe 'bach_repository::tools'
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = node['bach']['repository']['gems_directory']

directory gems_dir do
  mode 0555
end

package 'libaugeas-dev'
package 'libkrb5-dev'

# Fetch gems for all nodes
execute "bundler package" do
  cwd node['bach']['repository']['repo_directory']
  command "/opt/chefdk/embedded/bin/bundler package"
end

link "#{bins_dir}/gems" do
  to "#{gems_dir}"
end

#
# Install gems on the bootstrap, in the correct order.
# XXX: replace with bundler (Uh, Andrew not sure how/why;
#      gem seems to cover dependencies happily?)
#
%w{builder fpm json}.each do |local_gem|
  gem_binary = '/opt/chefdk/embedded/bin/gem'

  #
  # We are using an execute resource because gem_package does not
  # support --local.  We must use --local because without having
  # 'builder' already installed, it is not possible to generate the
  # gem index. (Rerunning gem install seems very harmless looking at strace
  # output and doesn't pin us to a version if we later upgrade)
  #
  execute "gem-install-#{local_gem}" do
    gem_file = Proc.new do |gem|
      local_gem_path = ::Dir.glob(::File.join(gems_dir, "#{gem}*.gem"))
      if local_gem_path.length != 1
        raise "Can not find just one Gem for #{gem}! Got:\n#{local_gem_path.join('\n')}"
      end
      local_gem_path = local_gem_path.first
    end
    command lazy { "#{gem_binary} install --local #{gem_file.call(local_gem)} --no-ri --no-rdoc" }
    cwd gems_dir
  end
end

execute 'gem-generate-index' do
  command 'gem generate_index --legacy'
  cwd bins_dir
  only_if {
    index_path = "#{bins_dir}/specs.4.8.gz"

    # If the index is missing, regenerate.
    # If any gems are newer than the index, regenerate.
    if !File.exists?(index_path)
      true
    else
      gem_mtimes = Dir.glob("#{gems_dir}/*.gem").map do |ff|
        File.mtime(ff)
      end

      gem_mtimes.max > File.mtime(index_path)
    end
  }
end
