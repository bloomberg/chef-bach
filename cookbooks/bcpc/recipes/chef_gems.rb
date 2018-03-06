#
# Cookbook Name:: bcpc
# Recipe:: chef_gems
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This recipe configures the chef gems required to begin a chef-bach
# run on a node.  It solves the chicken/egg problem of being unable to
# load the full cookbook set until after installing chef gems.
#
# This recipe is typically run during the "install_stubs" phase of
# cluster_assign_roles.
#
include_recipe 'bcpc::chef_poise_install'
include_recipe 'bcpc::chef_vault_install'
include_recipe 'bcpc::chef_faraday_install'
include_recipe 'bcpc::chef_cluster_def_install'
