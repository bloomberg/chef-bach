#
# "bins" contains all binaries and repositories, plus some builds
# "src" contains some builds
#
# The decision on whether to build in src_directory vs bins_directory
# was made by the old build_bins.sh.  For now, we are just replicating
# the behavior of the old script.
#
default[:bach][:repository][:repo_directory] = '/home/vagrant/chef-bcpc'
default[:bach][:repository][:bins_directory] = \
  ::File.join(node[:bach][:repository][:repo_directory], 'bins')
default[:bach][:repository][:gems_directory] = \
  ::File.join(node[:bach][:repository][:repo_directory], 'vendor/cache')
default[:bach][:repository][:src_directory] = \
  ::File.join(node[:bach][:repository][:repo_directory], 'src')

#
# This was originally envisioned as a release version for the
# repository.  It should probably be changed to reflect the chef-bach
# release number.
#
default[:bach][:repository][:apt_repo_version] = '0.5.0'

# Apt signing keys.
default[:bach][:repository][:private_key_path] = '/home/vagrant/apt_key.sec'
default[:bach][:repository][:public_key_path] = 
  default[:bach][:repository][:bins_directory] + '/apt_key.pub'
default[:bach][:repository][:ascii_key_path] = 
  default[:bach][:repository][:bins_directory] + '/apt_key.asc'

# Apt repository location
default[:bach][:repository][:apt_directory] =
  default[:bach][:repository][:bins_directory] + '/dists/' + 
  default[:bach][:repository][:apt_repo_version]

# mysql connector attributes
default[:bach][:repository][:mysql_connector].tap do |connector|
  connector[:version] = '5.1.37'

  connector[:tarball_md5sum] = '9ef584d3328735db51bd5dde3f602c22'

  connector[:url] =
    'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-' +
    node[:bach][:repository][:mysql_connector][:version] + '.tar.gz'

  connector[:package][:short_name] = 'mysql-connector-java'

  connector[:package][:name] =
    node[:bach][:repository][:mysql_connector][:package][:short_name] +
    '_' +
    node[:bach][:repository][:mysql_connector][:version] + '_all.deb'
end
