#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
include_recipe 'bach_repository::tools'
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = node['bach']['repository']['gems_directory']
gem_binary = '/opt/chefdk/embedded/bin/gem'

directory gems_dir do
  mode 0555
end

package 'libaugeas-dev'
package 'libkrb5-dev'

directory "#{node['bach']['repository']['repo_directory']}/vendor" do
  owner 'vagrant'
  mode 0755
end

directory "#{node['bach']['repository']['repo_directory']}/vendor/cache" do
  owner 'vagrant'
  mode 0755
end

directory "#{node['bach']['repository']['repo_directory']}/.bundle" do
  owner 'vagrant'
  mode 0755
end

file "#{node['bach']['repository']['repo_directory']}/.bundle/config" do
  content <<-EOF
---
BUNDLE_PATH: '#{node['bach']['repository']['repo_directory']}/vendor/bundle'
BUNDLE_DISABLE_SHARED_GEMS: 'true'
EOF
  owner 'vagrant'
  action :create
end

execute "bundler package" do
  cwd node['bach']['repository']['repo_directory']
  command "/opt/chefdk/embedded/bin/bundle package --path vendor/"
  # restore system PKG_CONFIG_PATH so mkmf::pkg_config()
  # can find system libraries
  environment 'PKG_CONFIG_PATH' => '/usr/lib/pkgconfig:' + \
    '/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig',
    'PATH' => '/opt/chefdk/embedded/bin/:/usr/local/sbin:/usr/local/bin:' + \
    '/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games'
  user 'vagrant'
end

link "#{bins_dir}/gems" do
  to "#{gems_dir}"
end

execute 'gem-generate-index' do
  command "#{gem_binary} generate_index"
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
