#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
include_recipe 'bach_repository::tools'
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = node['bach']['repository']['gems_directory']
gem_binary = node['bach']['repository']['gem_bin']
bundler_bin = node['bach']['repository']['bundler_bin']

package 'libaugeas-dev'
package 'libkrb5-dev'

directory "#{node['bach']['repository']['repo_directory']}/vendor" do
  owner 'vagrant'
  mode 0755
  recursive true
end

directory "#{node['bach']['repository']['repo_directory']}/.bundle" do
  owner 'vagrant'
  mode 0755
end

file "#{node['bach']['repository']['repo_directory']}/.bundle/config" do
  content <<-EOF.gsub(/^\s+/,'')
    ---
    BUNDLE_PATH: '#{node['bach']['repository']['repo_directory']}/vendor/bundle'
    BUNDLE_DISABLE_SHARED_GEMS: 'true'
  EOF
  owner 'vagrant'
  action :create
end

# https://github.com/bloomberg/chef-bach/issues/874
paths = %w(.bundle chef-bcpc/vendor/bundle chef-bcpc/vendor/cache)

execute 'Coerce Gem bundle permissions' do
  cwd '/home/vagrant'
  command "chown -Rf vagrant:vagrant #{paths.join(' ')}; " \
    "chmod -Rf u+rw #{paths.join(' ')}"
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
# This ruby_block checks for the presence of a Gemfile.lock in order
# to determine which scenario applies, then append a --deployment
# switch in the latter case.
#
ruby_block 'determine-bundler-command' do
  block do
    if File.exists?(File.join(node['bach']['repository']['repo_directory'],
                              'Gemfile.lock'))
      node.run_state[:bcpc_bootstrap_bundler_command] =
        "#{bundler_bin} install --deployment"
    else
      node.run_state[:bcpc_bootstrap_bundler_command] =
        "#{bundler_bin} install"
    end

    Chef::Resource::Log.new('bundler_command', run_context).tap do |ll|
      ll.level :info
      ll.message("Computed bundler command: " +
                 node.run_state[:bcpc_bootstrap_bundler_command])
    end.run_action(:write)
  end
end

execute 'bundler install' do
  cwd node['bach']['repository']['repo_directory']
  command lazy { node.run_state[:bcpc_bootstrap_bundler_command] }
  # restore system PKG_CONFIG_PATH so mkmf::pkg_config()
  # can find system libraries
  environment \
    'PKG_CONFIG_PATH' => %w(/usr/lib/pkgconfig
                            /usr/lib/x86_64-linux-gnu/pkgconfig
                            /usr/share/pkgconfig).join(':'),
    'PATH' => [::File.dirname(bundler_bin), ENV['PATH']].join(':')
  user 'vagrant'
end

execute 'bundler package' do
  cwd node['bach']['repository']['repo_directory']
  command "#{bundler_bin} package"
  # restore system PKG_CONFIG_PATH so mkmf::pkg_config()
  # can find system libraries
  environment \
    'PKG_CONFIG_PATH' => %w(/usr/lib/pkgconfig
                            /usr/lib/x86_64-linux-gnu/pkgconfig
                            /usr/share/pkgconfig).join(':'),
    'PATH' => [::File.dirname(bundler_bin), ENV['PATH']].join(':')
  user 'vagrant'
end

# if we make the cache directory before running bundle we get an error
# that we can't open a (non-existant) gem in the directory
directory gems_dir do
  owner 'vagrant'
  mode 0555
end

link "#{bins_dir}/gems" do
  to "#{gems_dir}"
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
