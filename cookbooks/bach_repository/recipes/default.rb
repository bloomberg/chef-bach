#
# Cookbook Name:: bach_repository
# Recipe:: default
#

ENV['http_proxy'] ||= Chef::Config.http_proxy
ENV['https_proxy'] ||= Chef::Config.https_proxy

# Apt packages containing build tools and pre-requisites.
include_recipe 'bach_repository::tools'

# Gems recipe has to run early because it includes fpm and related gems.
include_recipe 'bach_repository::gems'

# build cobbler -- cobbler's build has failes if Apache is already installed
include_recipe 'cobblerd::cobbler_source_build'

include_recipe 'bach_repository::chef'
include_recipe 'bach_repository::diamond'
include_recipe 'bach_repository::graphite'
include_recipe 'bach_repository::opentsdb'
include_recipe 'bach_repository::oracle_java'
include_recipe 'bach_repository::python_sources'
include_recipe 'bach_repository::spark'
include_recipe 'bach_repository::ubuntu'

# Python and ruby repos.
include_recipe 'bach_repository::python'

# Builds the apt repository: packages file, signatures, etc.
include_recipe 'bach_repository::apt'

# Install Java
include_recipe 'java::default'
include_recipe 'java::oracle_jce'

# build jvmkill lib
include_recipe 'bach_repository::jvmkill'

# download jmxtrans-agent
include_recipe 'bach_repository::jmxtrans_agent'

# Run after everything to fix perms.
include_recipe 'bach_repository::permissions'
