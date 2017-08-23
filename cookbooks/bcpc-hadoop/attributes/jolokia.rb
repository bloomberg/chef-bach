#
# Cookbook Name:: bcpc-hadoop
# Attributes: jolokia
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
# These settings only work for a single Jolokia agent running on a
# given host.
#
# If more agents are necessary, you will need to derive
# your own launch arguments for the JVM, in order to listen on an
# independent port.
#
node.default['bcpc']['jolokia'].tap do |jolokia|
  jolokia['policy_path'] = '/etc/bach/jolokia_security_policy.xml'
  jolokia['jar_path'] = '/usr/local/jolokia/lib/jolokia-jvm.jar'
  jolokia['whitelist'] = [
                          '127.0.0.1',
                          node[:bcpc][:bootstrap][:ip],
                          node[:bcpc][:management][:ip]
                         ]
  jolokia['host'] = '0.0.0.0'
  jolokia['port'] = 7777
  jolokia['jvm_args'] =
    "-javaagent:#{node[:bcpc][:jolokia][:jar_path]}=" \
    "port=#{node[:bcpc][:jolokia][:port]}," \
    "host=#{node[:bcpc][:jolokia][:host]}," \
    "policyLocation=file://#{node[:bcpc][:jolokia][:policy_path]}"
end
