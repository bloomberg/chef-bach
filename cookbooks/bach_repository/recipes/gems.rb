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

#
# Install gems on the bootstrap, in the correct order.
# XXX: replace with bundler (Uh, Andrew not sure how/why;
#      gem seems to cover dependencies happily?)
#
%w{builder fpm json}.each do |local_gem|

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
