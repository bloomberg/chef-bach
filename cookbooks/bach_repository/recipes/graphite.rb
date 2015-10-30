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
src_dir = node['bach']['repository']['src_directory']

[
 {
  name: 'pytz',
  version: '2015.6',
  url: 'https://pypi.python.org/packages/source/p/pytz/pytz-2015.6.zip',
  checksum: '2b3b20919afcf06f90a4e58aa2a2c82a601b71dd5a352af36478e5337d4a16cd'
 },
 {
  name: 'django',
  version: '1.5.4', 
  url: 'https://pypi.python.org/packages/source/D/Django/Django-1.5.4.tar.gz',
  checksum: '428defe3fd515dfc8613039bb0a80622a13fb4b988c5be48db07ec098ea1704e'
 },
 {
  name: 'carbon',
  version: '0.9.10+git20151021',
  url: 'https://github.com/graphite-project/carbon/archive/e1ec8e3a1fac12e19be450520947ef324647b8ae.tar.gz',
  checksum: '5d088a9fcfd304cb509abec7be49c7bb81055cb71aabe2091dda3b009740c280'
 },
 {
  name: 'whisper',
  version: '0.9.10+git20151021',
  url: 'https://github.com/graphite-project/whisper/archive/13f15a4aa5fcac2ed147854a732f9508f1f1dd8c.tar.gz',
  checksum: '9db97e5b724a380f0702cbe112f9c156faec60e8640cbeefd77364fc7555e5a1'
 },
 {
  name: 'graphite-web',
  version: '0.10.0-alpha+git20151027',
  url: 'https://github.com/graphite-project/graphite-web/archive/977b15467f03daffbe326166fd6e094b1d093e89.tar.gz',
  checksum: '47319a481e4147f916e9c727db861f62243cdce9fea32754a2e6539342cdeb00'
 },
].each do |package|

  ark "#{package[:name]}-#{package[:version]}" do
    url package[:url]
    path src_dir
    checksum package[:checksum]
    action :put
  end

  deb_name = "python-#{package[:name]}_#{package[:version]}_all.deb"

  fpm_command = 
    if(package[:name] == 'graphite-web')
      "fpm --python-install-lib /opt/graphite/webapp " +
        "-p #{bins_dir}/#{deb_name} " +
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    else
      "fpm --python-install-bin /opt/graphite/bin " +
        "-p #{bins_dir}/#{deb_name} " +
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    end

  execute "fpm-#{package[:name]}" do
    command fpm_command
    cwd src_dir
    not_if{ File.exists?("#{bins_dir}/#{deb_name}") }
  end

end
