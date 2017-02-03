#
# Cookbook Name:: bcpc
# Recipe:: certs
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

require 'openssl'
include_recipe 'bcpc::default'
include_recipe 'bcpc::chef_vault_install'

template "/tmp/openssl.cnf" do
    source "openssl.cnf.erb"
    owner "root"
    group "root"
    mode 00644
end

node.default[:temp][:value] = ""
bootstrap = get_bootstrap
key = OpenSSL::PKey::RSA.new 2048;

results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

ruby_block "initialize-ssh-keys" do
    block do
        require 'net/ssh'
        pubkey = "#{key.ssh_type} #{[ key.to_blob ].pack('m0')}"
        make_config('ssh-public-key', pubkey)
        if get_config('ssl-certificate').nil? && get_config('certificate','ssl','os').nil? then
            node.set[:temp][:value] = %x[openssl req -config /tmp/openssl.cnf -extensions v3_req -new -x509 -passout pass:temp_passwd -newkey rsa:4096 -out /dev/stdout -keyout /dev/stdout -days 1095 -subj "/C=#{node['bcpc']['country']}/ST=#{node['bcpc']['state']}/L=#{node['bcpc']['location']}/O=#{node['bcpc']['organization']}/OU=#{node['bcpc']['region_name']}/CN=#{node['bcpc']['domain_name']}/emailAddress=#{node['bcpc']['admin_email']}"]
        end
    end
    notifies :create, 'ruby_block[chef_vault_secret]', :immediately
end

ssh_private_key = get_config("ssh-private-key")
if ssh_private_key.nil?
  ssh_private_key = key.to_pem
end

chef_vault_secret 'ssh' do  
  #
  # For some reason, we are compelled to specify a provider.
  # This will probably break if we ever move to chef-vault cookbook 2.x
  #
  provider ChefVaultCookbook::Provider::ChefVaultSecret

  data_bag 'os'
  raw_data({ "private-key" => key.to_pem })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :create_if_missing
end

ruby_block "chef_vault_secret" do
  block do
    if node[:temp][:value] != ""
      ssl_certificate = %x[echo "#{node[:temp][:value]}" | openssl x509]
      ssl_private_key = %x[echo "#{node[:temp][:value]}" | openssl rsa -passin pass:temp_passwd -out /dev/stdout]
    else
      ssl_certificate = get_config("ssl-certificate")
      ssl_private_key = get_config("ssl-private-key")
    end
    vault_resource = resources("chef_vault_secret[ssl]")
    vault_resource.raw_data({ 'private-key' => ssl_private_key, "certificate" => ssl_certificate })
  end
  action :nothing
end

chef_vault_secret "ssl" do
  #
  # For some reason, we are compelled to specify a provider.
  # This will probably break if we ever move to chef-vault cookbook 2.x
  #
  provider ChefVaultCookbook::Provider::ChefVaultSecret

  if node[:temp][:value] != ""
    ssl_certificate = %x[echo "#{node[:temp][:value]}" | openssl x509]
    ssl_private_key = %x[echo "#{node[:temp][:value]}" | openssl rsa -passin pass:temp_passwd -out /dev/stdout]
  else
    ssl_certificate = get_config("ssl-certificate")
    ssl_private_key = get_config("ssl-private-key")
  end
  data_bag 'os'
  raw_data ({ 'private-key' => ssl_private_key, 'certificate' => ssl_certificate })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :create_if_missing
end

directory "/root/.ssh" do
    owner "root"
    group "root"
    mode 00700
end

template "/root/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner "root"
    group "root"
    mode 00644
end

template "/root/.ssh/id_rsa" do
    source "id_rsa.erb"
    owner "root"
    group "root"
    mode 00600
end

template "/etc/ssl/certs/ssl-bcpc.pem" do
    source "ssl-bcpc.pem.erb"
    owner "root"
    group "root"
    mode 00644
end

directory "/etc/ssl/private" do
    owner "root"
    group "root"
    mode 00700
end

template "/etc/ssl/private/ssl-bcpc.key" do
    source "ssl-bcpc.key.erb"
    owner "root"
    group "root"
    mode 00600
end

