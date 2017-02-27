#
# Cookbook Name:: bach_repository
# Recipe:: graphite
#
#
# This recipe extracts tarballs and runs fpm to create debs hardcoded
# to /opt/graphite.
#
# Warning: fragile.
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']
fpm_path = node['bach']['repository']['fpm_bin']

#
# When a shell script built these packages, it assigned an epoch using
# the UNIX epoch.  Now we're stuck with this convention in order to
# allow newer versions to overwrite older ones.
#
epoch = Time.now.strftime("%s")

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
  name: 'pyparsing',
  version: '2.0.6',
  url: 'https://pypi.python.org/packages/source/p/pyparsing/pyparsing-2.0.6.zip',
  checksum: '697f04b1b5d01741f4f7b7267ff2f2cc845c336e65efa71609339a250a0e9c72'
 },
 {
  name: 'carbon',
  version: '0.10.0-rc1+git20161102',
  url: 'https://github.com/graphite-project/carbon/archive/' \
    '0a6944d144955dc398f722384bce2e42ed348f61.zip',
  checksum: 'a123e26f36dfe3685e764fd1ea6b87465101f3b5778856744b133a00d771a6b0'
 },
 {
  name: 'whisper',
  version: '0.10.0-rc1+git20161102',
  url: 'https://github.com/graphite-project/whisper/archive/' \
    '0ff96849376fa6943214f6634be7225f2f44cd2e.zip',
  checksum: 'bfadd161981f36a0ef218ce9021035d85480511f9d4e75db88beac6ab03d9f94'
 },
 {
  name: 'graphite-web',
  version: '0.10.0-rc1+git20161102',
  url: 'https://github.com/graphite-project/graphite-web/archive/' \
    '8b142c8d9130857b6d47981e0e92930984a250e1.zip',
  checksum: 'ed6134ce114f243db47ca3006ac5a2df7fa6d3d231ab072a82d0707220e08af2'
 },
].each do |package|

  deb_name = "python-#{package[:name]}_#{package[:version]}_all.deb"
  deb_path = ::File.join(bins_dir,deb_name)

  log "URL: #{package[:url]}, target deb path: #{deb_path}"
  
  ark "#{package[:name]}-#{package[:version]}" do
    url package[:url]
    path src_dir
    checksum package[:checksum]
    action :put
    not_if {
      File.exists?(deb_path)
    }
  end

  fpm_command = 
    if(package[:name] == 'graphite-web')
      "#{fpm_path} --python-install-lib /opt/graphite/webapp " +
        "--epoch #{epoch} " +
        "-p #{deb_path} " +
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    else
      "#{fpm_path} --python-install-bin /opt/graphite/bin " +
        "--epoch #{epoch} " +
        "-p #{deb_path} " +
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    end

  execute "fpm-#{package[:name]}" do
    command fpm_command
    cwd src_dir
    environment 'PATH' => "/opt/chefdk/embedded/bin:#{ENV['PATH']}",
                'BUNDLE_GEMFILE' =>
                  "#{node[:bach][:repository][:repo_directory]}/Gemfile"
    creates deb_path
  end
end
