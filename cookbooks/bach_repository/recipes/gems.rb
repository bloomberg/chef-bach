#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
include_recipe 'bach_repository::tools'
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = "#{bins_dir}/gems"

directory gems_dir do
  mode 0555
end

#
# This array is deliberately ordered to get the correct install order.
# TODO: replace with bundler
#
bootstrap_gems = [
                   ['json','1.8.3'],
                   ['cabin', '0.7.2'],
                   ['arr-pm', '0.0.9'],
                   ['backports', '2.6.2'],
                   ['clamp', '0.6.5'],
                   ['childprocess', '0.5.9'],
                   ['ffi', '1.9.14'],
                   ['fpm', '1.3.3'],
                   ['builder', '3.2.2']
                 ]

# This array is just alphabetically sorted.
worker_gems = [
                ['chef-rewind', '0.0.9'],
                ['chef-vault', '2.9.0'],
                ['mini_portile2', '2.1.0'],
                ['mysql2', '0.4.4'],
                ['nokogiri', '1.6.8.1'],
                ['patron', '0.8.0'],
                ['rake-compiler', '1.0.1'],
                ['rkerberos', '0.1.5'],
                ['ruby-augeas', '0.5.0'],
                ['sequel', '4.36.0'],
                ['simple-graphite', '2.1.0'],
                ['webhdfs', '0.5.5'],
                ['wmi-lite', '1.0.0'],
                ['zabbixapi', '2.4.9'],
                ['zookeeper', '1.4.7'],
              ]

# Fetch gems for all nodes
(bootstrap_gems + worker_gems).each do |gem_name, gem_version|
  execute "gem_fetch[#{gem_name}]" do
    cwd gems_dir
    command "/usr/bin/gem fetch #{gem_name} -v #{gem_version}"
    creates "#{gems_dir}/#{gem_name}-#{gem_version}.gem"
    notifies :run, 'execute[gem-generate-index]'
  end

  link "#{gems_dir}/#{gem_name}.gem" do
    to "#{gems_dir}/#{gem_name}-#{gem_version}.gem"
    notifies :run, 'execute[gem-generate-index]'
  end
end

#
# Install gems on the bootstrap, in the correct order.
# TODO: replace with bundler
#
bootstrap_gems.each do |package_name, package_version|

  local_gem_path =
    gems_dir + '/' + package_name + '-' + package_version + '.gem'

  gem_binary = '/usr/bin/gem'

  #
  # We are using an execute resource because gem_package does not
  # support --local.  We must use --local because without having
  # 'builder' already installed, it is not possible to generate the
  # gem index.
  #
  execute "gem-install-#{package_name}" do
    command "#{gem_binary} install --local #{local_gem_path} --no-ri --no-rdoc"
    cwd gems_dir
    not_if "#{gem_binary} list -i #{package_name} -v #{package_version}"
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
