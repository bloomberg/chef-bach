#
# Cookbook Name:: bcpc_kafka
# Library:: utils
#
# Copyright 2013, Bloomberg Finance L.P.
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

# The method GET_ZK_NODES searches for Zookeeper nodes at two levels (Run List and Roles).
# During a chef-client run a run list is updated before the chef-client run and is available for
# searching nodes. Roles and recipes are updated after the chef-client run completes and commits
# data back to the chef-server

def get_zk_nodes
  rl_results = search(:node, "role:BCPC-Kafka-Head-Zookeeper AND chef_environment:#{node.chef_environment}")
  rl_results.map!{|x| x[:hostname] == node[:hostname] ? node : x}
  ro_results = search(:node, "roles:BCPC-Kafka-Head-Zookeeper AND chef_environment:#{node.chef_environment}")
  ro_results.map!{|x| x[:hostname] == node[:hostname] ? node : x}
  results = rl_results.concat ro_results
  return results.uniq{|x| x[:hostname]}.sort
end
