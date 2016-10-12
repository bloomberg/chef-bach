#
# Cookbook Name:: bcpc
# Recipe:: cluster_local_repository
#
# Copyright 2016, Bloomberg Finance L.P.
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
# This recipe configures clients to use the apt repository maintained
# on the bootstrap node.
#
# This is normally done by "install-chef.sh" when the chef client is
# installed.  We do it again during the chef run in order to correct
# any issues and update the apt sources.
#

require 'uri'
bootstrap_uri = URI.parse(get_binary_server_url)

file '/etc/apt/apt.conf.d/99cluster_local_repository_proxy' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    Acquire::http::Proxy {
      #{bootstrap_uri.host} DIRECT;
    };
  EOM
end

apt_repository 'bcpc' do
  uri get_binary_server_url
  distribution '0.5.0'
  arch 'amd64'
  components ['main']
  trusted true
  key URI.join(get_binary_server_url, 'apt_key.pub').to_s
end
