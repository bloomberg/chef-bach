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

#
# On the bootstrap, the bootstrap-hosted apt mirror will be a local
# filesystem path.  On all other nodes, it is an http path, to the
# bootstrap.
#
require 'uri'

user = node['bcpc']['bootstrap']['admin']['user']


apt_uri = if node[:fqdn] == get_bootstrap
            URI.parse("file:///home/#{user}/chef-bcpc/bins")
          else
            URI.parse(get_binary_server_url)
          end

# No proxy will ever be necessary to reach the bootstrap.
if apt_uri.host
  file '/etc/apt/apt.conf.d/99cluster_local_repository_proxy' do
    mode 0444
    content <<-EOM.gsub(/^ {6}/,'')
      Acquire::http::Proxy {
        #{apt_uri.host} DIRECT;
      };
    EOM
  end
end

unless node[:fqdn] == get_bootstrap
  bcpc_apt_key_path = File.join(Chef::Config[:file_cache_path],
                                'bcpc-cluster-local-repo.gpg')

  file bcpc_apt_key_path do
    mode 0444
    content Base64.decode64(get_config!('bootstrap-gpg-public_key_base64'))
  end

  ruby_block 'get-bootstrap-gpg-fingerprint' do
    block do
      require 'mixlib/shellout'
      cc = Mixlib::ShellOut.new('gpg',
                                '--with-fingerprint',
                                bcpc_apt_key_path)
      cc.run_command
      cc.error!
      node.run_state['bootstrap_gpg_fingerprint'] =
        cc.stdout.lines.select do |line|
        line.include?('fingerprint =')
      end.first.gsub(/.*fingerprint =/, '').gsub(/\s/, '').chomp
    end
  end

  execute 'install-bootstrap-gpg' do
    command lazy { "apt-key add '#{bcpc_apt_key_path}'" }
  end
end

apt_repository 'bcpc' do
  uri apt_uri.to_s
  distribution '0.5.0'
  arch 'amd64'
  components ['main']
  if node[:fqdn] == get_bootstrap
    trusted true
  else
    key node.run_state['bootstrap_gpg_fingerprint']
  end
end

execute 'apt-get update' do
  action :run
end
