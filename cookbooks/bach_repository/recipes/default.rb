#
# Cookbook Name:: bach_repository
# Recipe:: default
#

ENV['http_proxy'] ||= Chef::Config.http_proxy
ENV['https_proxy'] ||= Chef::Config.https_proxy

# Mostly build tools, plus fpm and pypi.
include_recipe 'bach_repository::tools'

include_recipe 'bach_repository::chef'
include_recipe 'bach_repository::diamond'
include_recipe 'bach_repository::graphite'
include_recipe 'bach_repository::jmxtrans'
include_recipe 'bach_repository::kafka'
include_recipe 'bach_repository::oracle_java'
include_recipe 'bach_repository::python_sources'
include_recipe 'bach_repository::spark'
include_recipe 'bach_repository::ubuntu'

# Python and ruby repos.
include_recipe 'bach_repository::gems'
include_recipe 'bach_repository::python'

# Builds the apt repository: packages file, signatures, etc.
include_recipe 'bach_repository::apt'

# Run after everything to fix perms.
include_recipe 'bach_repository::permissions'
