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
default[:bach][:repository][:bundle_directory] = \
  ::File.join(node[:bach][:repository][:repo_directory], 'vendor')
default[:bach][:repository][:gems_directory] = \
  ::File.join(node[:bach][:repository][:bundle_directory], 'cache')
default[:bach][:repository][:src_directory] = \
  ::File.join(node[:bach][:repository][:repo_directory], 'src')

#
# This was originally envisioned as a release version for the
# repository.  It should probably be changed to reflect the chef-bach
# release number.
#
default[:bach][:repository][:apt_repo_version] = '0.5.0'

default['bach']['repository']['bundler_bin'] = '/opt/chefdk/embedded/bin/bundle'
default['bach']['repository']['gem_bin'] = '/opt/chefdk/embedded/bin/gem'
default['bach']['repository']['fpm_bin'] = \
  "#{node['bach']['repository']['bundler_bin']} exec fpm"

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

# Get the URLs to download Java installation packages
# use java cookbook (https://github.com/agileorbit-cookbooks/java)
default['bach']['repository']['java'].tap do |java|
  java['jce_url']      = node['java']['oracle']['jce']['8']['url']
  java['jce_checksum'] = node['java']['oracle']['jce']['8']['checksum']
  java['jdk_url']      = node['java']['jdk']['8']['x86_64']['url']
  java['jdk_checksum'] = node['java']['jdk']['8']['x86_64']['checksum']
end

# Install Java on bootstrap node
default['java']['jdk_version'] = 8
default['java']['install_flavor'] = 'oracle'
default['java']['accept_license_agreement'] = true
default['java']['oracle']['accept_oracle_download_terms'] = true
default['java']['oracle']['jce']['enabled'] = true

# Set the JAVA_HOME for Hadoop components
default['bcpc']['hadoop']['java'] = "/usr/lib/jvm/java-8-oracle-amd64"

# jmxtrans-agent (https://github.com/jmxtrans/jmxtrans-agent)
default['bach']['repository']['jmxtrans_agent']['download_url'] = 'https://github.com/jmxtrans/jmxtrans-agent/releases/download/jmxtrans-agent-1.2.5/jmxtrans-agent-1.2.5.jar'
