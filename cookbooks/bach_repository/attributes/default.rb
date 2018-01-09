#
# "bins" contains all binaries and repositories, plus some builds
# "src" contains some builds
#
# The decision on whether to build in src_directory vs bins_directory
# was made by the old build_bins.sh.  For now, we are just replicating
# the behavior of the old script.
#

default['bach']['repository']['build']['user'] = \
  ENV['SUDO_USER'] || ENV['USER'] || 'vagrant'
user = node['bach']['repository']['build']['user']

default[:bach][:repository][:repo_directory] = "/home/#{user}/chef-bcpc"
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
default[:bach][:repository][:private_key_path] = "/home/#{user}/apt_key.sec"
default[:bach][:repository][:public_key_path] =
  default[:bach][:repository][:bins_directory] + '/apt_key.pub'
default[:bach][:repository][:ascii_key_path] =
  default[:bach][:repository][:bins_directory] + '/apt_key.asc'

# Ruby repository location
default[:bach][:repository][:gem_server] = 'https://rubygems.org'

# Apt repository location
default[:bach][:repository][:apt_directory] =
  default[:bach][:repository][:bins_directory] + '/dists/' +
  default[:bach][:repository][:apt_repo_version]

# Install Java on bootstrap node
default['java']['jdk_version'] = 8
default['java']['install_flavor'] = 'oracle'
default['java']['accept_license_agreement'] = true
default['java']['oracle']['accept_oracle_download_terms'] = true
default['java']['oracle']['jce']['enabled'] = true

# Set the JAVA_HOME for Hadoop components
default['bach']['repository']['java'] = "/usr/lib/jvm/java-8-oracle-amd64"

# jmxtrans-agent (https://github.com/jmxtrans/jmxtrans-agent)
default['bach']['repository']['jmxtrans_agent']['download_url'] = 'https://github.com/jmxtrans/jmxtrans-agent/releases/download/jmxtrans-agent-1.2.5/jmxtrans-agent-1.2.5.jar'
default['bach']['repository']['jmxtrans_agent']['checksum'] = 'd351ac0b863ffb2742477001296f65cbca6f8e9bb5bec3dc2194c447d838ae17'

# OpenTSDB deb package details
default['bach']['repository']['opentsdb']['version'] = '2.3.0'
default['bach']['repository']['opentsdb']['package_name'] = "opentsdb-#{node['bach']['repository']['opentsdb']['version']}_all.deb"
default['bach']['repository']['opentsdb']['download_url'] = "https://github.com/OpenTSDB/opentsdb/releases/download/v#{node['bach']['repository']['opentsdb']['version']}/#{node['bach']['repository']['opentsdb']['package_name']}"
default['bach']['repository']['opentsdb']['checksum'] = 'eb3568582180a7cf72f629e59ed9dc545d183e57abb29a1bf0d9c328ef0f2982'
