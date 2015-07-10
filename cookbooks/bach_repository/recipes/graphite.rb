#
# Cookbook Name:: bach_repository
# Recipe:: graphite
#
#
# This recipe extracts tarballs and runs fpm to create debs.
# Warning: fragile.
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

{
  'carbon' => 
    'f1a1d61a0bf9e2ff3c42c01310a59572e527139c7ce73bdbeb25d8813b78d2b9',
  'whisper' =>
    '5476285366f1af92e3a95c738b10d8d944b58b4931f301a19a7f849453a44fd3',
  'graphite-web' =>
    '6439598fbc03b3d1bf29b01295e2386e750c9e94e032596da857557fd07825b8'
}.each do |package_name, package_checksum|
  package_version = '0.9.10'
  package_file = "#{package_name}-#{package_version}.tar.gz"
  package_url =
    "http://pypi.python.org/packages/source/#{package_name.chars.first}" +
    "/#{package_name}/#{package_file}"

  remote_file "#{bins_dir}/#{package_file}" do
    source package_url
    mode 0444
    checksum package_checksum
  end

  execute "extract-#{package_name}" do
    command "tar -xzf #{bins_dir}/#{package_file}"
    cwd bins_dir
    not_if{ Dir.exists?( "#{bins_dir}/#{package_name}-#{package_version}" ) }
  end

  fpm_command = 
    if(package_name == 'graphite-web')
      "fpm --python-install-bin /opt/graphite/webapp " +
        "-s python -t deb #{package_name}-#{package_version}/setup.py"
    else
      "fpm --python-install-bin /opt/graphite/bin " +
        "-s python -t deb #{package_name}-#{package_version}/setup.py"
    end

  deb_name = "python-#{package_name}_#{package_version}_all.deb"
  execute "fpm-#{package_name}" do
    command fpm_command
    cwd bins_dir
    not_if { File.exists?( "#{bins_dir}/#{deb_name}" ) }
  end
end
