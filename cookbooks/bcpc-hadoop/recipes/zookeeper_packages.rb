#
# Cookbook Name:: bcpc-hadoop
# Recipe:: zookeeper_packages
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
# This recipe installs the Hortonworks HDP packages associated with
# the Zookeeper server.  As a side effect, package installation will
# create the Zookeeper user, if absent.
#
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

include_recipe 'bcpc-hadoop::hdp_repo'

package hwx_pkg_str('zookeeper-server',
                    node[:bcpc][:hadoop][:distribution][:release]) do
  action :upgrade
end

hdp_select('zookeeper-server',
           node[:bcpc][:hadoop][:distribution][:active_release])
