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
#XXX  to "#{gems_dir}/#{gem_name}-#{gem_version}.gem"
  to "#{gems_dir}"
end

#
# Install gems on the bootstrap, in the correct order.
# TODO: replace with bundler
#
%w{builder fpm json}.each do |local_gem|
  local_gem_path = ::Dir.glob(::File.join(gems_dir, "#{local_gem}*.gem")).first
  gem_binary = '/opt/chef/embedded/bin/gem'

  #
  # We are using an execute resource because gem_package does not
  # support --local.  We must use --local because without having
  # 'builder' already installed, it is not possible to generate the
  # gem index. (Rerunning gem install seems very harmless looking at strace
  # output and doesn't pin us to a version if we later upgrade)
  #
  execute "gem-install-#{local_gem}" do
    command "#{gem_binary} install --local #{local_gem_path} --no-ri --no-rdoc"
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
