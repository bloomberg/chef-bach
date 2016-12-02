#
# Cookbook Name:: bach_repository
# Recipe:: tools
#

#
# If we are executing in local mode, we may not have correct mirror
# definitions for use by the Ubuntu cookbook.
#
# The hacky solution is to execute 'apt-get update' blindly, without
# explicitly configuring any mirrors.
#
if Chef::Config[:local_mode]
  execute 'apt-get update' do
    ignore_failure true
  end
else
  include_recipe 'ubuntu'
  include_recipe 'apt'
end

include_recipe 'build-essential'

#
# This long list of dev/packaging tools originally came from build_bins.sh.
#
[
  'apt-utils',
  'autoconf',
  'autogen',
  'cdbs',
  'dpkg-dev',
  'gcc',
  'git',
  'haveged',
  'libldap2-dev',
  'libmysqlclient-dev',
  'libtool',
  'make',
  'patch',
  'pkg-config',
  'pbuilder',
  'python-all-dev',
  'python-configobj',
  'python-mock',
  'python-pip',
  'python-setuptools',
  'python-stdeb',
  'python-support',
  'rake',
  'rsync',
  'ruby',
  'ruby-dev',
  'unzip',
].each do |pkg|
  package pkg do
    action :install
    timeout 3600 if respond_to?(:timeout)
  end
end
