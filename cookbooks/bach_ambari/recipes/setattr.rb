#
# Cookbook Name:: ambari-chef
# Recipe:: setattr
#
# Copyright (c) 2016 Artem Ervits, All Rights Reserved.

# Override defaults for the Java cookbook
node.override['java']['jdk_version'] = '8'
node.override['java']['install_flavor'] = "oracle"
node.override['java']['accept_license_agreement'] = true
node.override['java']['oracle']['jce']['enabled'] = true
node.override['java']['oracle']['accept_oracle_download_terms'] = true
node.override['java']['set_default'] = true
