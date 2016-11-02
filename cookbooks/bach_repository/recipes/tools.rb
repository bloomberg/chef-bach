#
# Cookbook Name:: bach_repository
# Recipe:: tools
#

execute 'apt-get update' do
  action :run
end

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
    action :upgrade
    timeout 3600 if respond_to?(:timeout)
  end
end

#
# This array is deliberately ordered to get the correct install order.
# These gems are also added to the repo in bach_repository::gems
#
[
  ['json','1.8.3'],
  ['cabin', '0.7.2'],
  ['fpm', '1.3.3'],
  ['builder', '3.2.2']
].each do |package_name, package_version|
  gem_package package_name do
    version package_version
  end
end

