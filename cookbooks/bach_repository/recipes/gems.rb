#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
include_recipe 'bach_repository::tools'
repo_dir =  node['bach']['repository']['repo_directory']
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = node['bach']['repository']['gems_directory']
gem_binary = node['bach']['repository']['gem_bin']
bundler_bin = node['bach']['repository']['bundler_bin']

package 'libaugeas-dev'
package 'libkrb5-dev'

user = node['bach']['repository']['build']['user']

directory "#{node['bach']['repository']['repo_directory']}/vendor" do
  owner "#{user}"
  mode 0755
  recursive true
end

directory "#{node['bach']['repository']['repo_directory']}/.bundle" do
  owner "#{user}"
  mode 0755
end

file "#{node['bach']['repository']['repo_directory']}/.bundle/config" do
  content <<-EOF.gsub(/^\s+/,'')
    ---
    BUNDLE_PATH: '#{node['bach']['repository']['repo_directory']}/vendor/bootstrap'
    BUNDLE_GEMFILE: '#{node['bach']['repository']['repo_directory']}/gemfiles/bootstrap.gemfile'
    BUNDLE_DISABLE_SHARED_GEMS: 'true'
  EOF
  owner "#{user}"
  action :create
end

# https://github.com/bloomberg/chef-bach/issues/874
paths = %W(.bundle chef-bcpc/vendor/bootstrap chef-bcpc/bootstrap/cache #{gems_dir} #{bins_dir})

execute 'Coerce Gem and Bins Pre-Run Permissions' do
  cwd "/home/#{user}"
  command "chown -Rf #{user}:root #{paths.join(' ')}; " \
    "chmod -Rf ug+rw #{paths.join(' ')}"
  # Some paths may not exist yet, and that's ok.
  ignore_failure true
end

#
# Bundler gets run in two completely different contexts.  The first
# time, it is run on an internet-connected host to generate a
# self-contained package of gems and a Gemfile.lock.  The second time
# it is run on an internet-disconnected host only to verify the
# extracted package is complete.
#
# This ruby_block checks for the presence of a Gemfile.lock on the file
# system and in the Git repo (as required by Bundler) in order
# to determine which scenario applies, then append a --deployment
# switch in the latter case.
#
ruby_block 'determine-bundler-command' do
  block do
    gemfile_lock_path = File.join(node['bach']['repository']['repo_directory'],
                                  'gemfiles', 'bootstrap.gemfile.lock')
    gemfile_lock_cmd = Mixlib::ShellOut.new('git', 'diff', '--name-status',
                                            gemfile_lock_path)
    gemfile_lock_cmd.run_command
    if File.exists?(gemfile_lock_path) && !gemfile_lock_cmd.error?
      node.run_state[:bcpc_bootstrap_bundler_command] =
        "#{bundler_bin} install --deployment"
    else
      node.run_state[:bcpc_bootstrap_bundler_command] =
        "#{bundler_bin} install"
    end
    Chef::Log.info "bundler command: #{node.run_state[:bcpc_bootstrap_bundler_command]}"
    Chef::Resource::Log.new('bundler_command', run_context).tap do |ll|
      ll.level :info
      ll.message("Computed bundler command: " +
                 node.run_state[:bcpc_bootstrap_bundler_command])
    end.run_action(:write)
  end
end

# restore system PKG_CONFIG_PATH so mkmf::pkg_config()
# can find system libraries
bootstrap_environment =  {
  'PKG_CONFIG_PATH' => %w(/usr/lib/pkgconfig
                          /usr/lib/x86_64-linux-gnu/pkgconfig
                          /usr/share/pkgconfig).join(':'),
  'PATH' => [::File.dirname(bundler_bin), ENV['PATH']].join(':')
}

proxy = node['bach']['repository']['proxy']
if ! proxy.nil?
  bootstrap_environment['http_proxy'] = proxy
  bootstrap_environment['https_proxy'] = proxy
end

execute 'bundler install' do
  cwd node['bach']['repository']['repo_directory']
  # although implicit we need to be explicit with --path to
  # work around bundler #4571
  command lazy { node.run_state[:bcpc_bootstrap_bundler_command] + ' --path #{repo_dir}' }
  environment bootstrap_environment
  user "#{user}"
end

execute 'bundler package' do
  cwd node['bach']['repository']['repo_directory']
  # although implicit we need to be explicit with --path to
  # work around bundler #4571
  command "#{bundler_bin} package --path #{repo_dir}"
  environment bootstrap_environment
  user "#{user}"
end

# if we make the cache directory before running bundle we get an error
# that we can't open a (non-existant) gem in the directory
directory gems_dir do
  owner "#{user}"
  group "root"
  mode 0555
end

link "#{bins_dir}/gems" do
  to "#{gems_dir}"
end

# HACK to install cluster_def if it exists
# since bundler will not do it for us

execute 'build cluster_def.gem' do
  cwd "#{repo_dir}/lib/cluster-def-gem"
  command "chef exec gem build cluster_def.gemspec"
  creates "#{repo_dir}/lib/cluster-def-gem/cluster_def-0.1.0.gem"
end

execute 'copy cluster_def gem' do
  command "cp #{repo_dir}/lib/cluster-def-gem/cluster_def-*.gem #{gems_dir}"
  creates "#{gems_dir}/cluster_def-0.1.0.gem"
end

execute 'gem-generate-index' do
  command "#{gem_binary} generate_index"
  cwd bins_dir
  only_if do
    index_path = "#{bins_dir}/specs.4.8.gz"

    # If the index is missing, regenerate.
    # If any gems are newer than the index, regenerate.
    if !File.exist?(index_path)
      true
    else
      gem_mtimes = Dir.glob("#{gems_dir}/*.gem").map do |ff|
        File.mtime(ff)
      end

      gem_mtimes.max > File.mtime(index_path)
    end
  end
end

execute 'Coerce Gem and Bins Update Permissions' do
  cwd "/home/#{user}"
  command "chown -Rf #{user}:root #{paths.join(' ')}; " \
    "chmod -Rf ug+rw #{paths.join(' ')}"
  ignore_failure true
end

#
