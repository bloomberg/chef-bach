#
# Cookbook Name:: bach_repository
# Recipe:: tools
#

execute 'apt-get update'

# This long list of dev/packaging tools originally came from build_bins.sh.
# It has not been checked for correctness.
package [
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
         'ruby-dev',
         'ruby1.9.1-dev',
         'ruby1.9.3',
         'rubygems',
         'unzip',
        ] do 
  action :install
  timeout 3600
end

execute 'update-alternatives --set ruby /usr/bin/ruby1.9.1'

execute 'update-alternatives --set gem /usr/bin/gem1.9.1'

# The classic package mangler
gem_package 'fpm' do
  version '1.4.0'
end

# Required for gem indexing
gem_package 'builder' do
  version '3.2.2'
end

