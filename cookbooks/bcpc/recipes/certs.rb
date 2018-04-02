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

# Generates ssh and ssl key-pairs
# 1. public key (or certificate) will be stored in data bag. e.g. 'ssh-public-key'
# 2. private key will be stored in chef vault. e.g. ('private-key', 'ssh', 'os')

require 'openssl'
require 'net/ssh'
include_recipe 'bcpc::default'
include_recipe 'bcpc::chef_vault_install'

bootstrap = get_bootstrap
key = OpenSSL::PKey::RSA.new 2048;

results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
all_nodes = results == "" ? node['fqdn'] : results

# ----------------------------- SSH ------------------------------
ruby_block 'generate-ssh-keypair' do
  block do
    Chef::Log.info('Start generate-ssh-keypair.')
    sshkey = OpenSSL::PKey::RSA.new node['bcpc']['ssh']['key_size']

    # get public key
    ssh_public_key = "#{sshkey.ssh_type} #{[sshkey.to_blob].pack('m0')}"
    # Chef::Log.info("ssh_public_key=#{ssh_public_key}")

    # save to data bag for public access
    make_config('ssh-public-key', ssh_public_key)

    # get private key
    ssh_private_key = sshkey.to_pem
    # Chef::Log.info("ssh_private_key = #{node.run_state['new_ssh_private_key']}")

    # pass to chef-vault
    node.run_state['new_ssh_private_key'] = ssh_private_key
    Chef::Log.info('Generate-ssh-keypair finished.')
  end
  only_if { get_config('ssh-public-key').nil? || get_config('private-key', 'ssh', 'os').nil? }
  notifies :create, 'chef_vault_secret[ssh]', :immediate
  # regenerate if missing either public or pirvate key
end

# save to chef-vault after new keypair is generated.
chef_vault_secret 'ssh' do
  data_bag 'os'
  raw_data(lazy { { 'private-key' => node.run_state['new_ssh_private_key'] } })
  admins "#{all_nodes},#{bootstrap}"
  search '*:*'
  action :nothing
end

# ------------------------------- SSL ----------------------------

# the DNS and IP lists includes
# 1. the global virtual IP and cluster virtual hostname
# 2. head nodes machine IP and hostnames
ip_list = [node['bcpc']['management']['vip']]
dns_list = [node['bcpc']['management']['viphost']]

get_static_head_node_local_ip_list.each do |ip|
  ip_list.push(ip) unless ip.nil?
end

get_head_node_names.each do |fqdn|
  dns_list.push(fqdn) unless fqdn.nil?
end

Chef::Log.info("ssl-keypair: IP list=#{ip_list}")
Chef::Log.info("ssl-keypair: DNS list=#{dns_list}")

# construct the config file for generating the ssl keypair
template node['bcpc']['ssl']['conf_file'] do
  source 'bach_openssl.cnf.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables(ip_list: ip_list, dns_list: dns_list)
end

# generate the ssl keypair
ruby_block 'generate-ssl-keypair' do
  block do
    Chef::Log.info('Start generate-ssl-keypair.')
    subj_str = "/C=#{node['bcpc']['country']}" \
               "/ST=#{node['bcpc']['state']}" \
               "/L=#{node['bcpc']['location']}" \
               "/O=#{node['bcpc']['organization']}" \
               "/OU=#{node['bcpc']['region_name']}" \
               "/CN=#{node['bcpc']['domain_name']}" \
               "/emailAddress=#{node['bcpc']['admin_email']}"
    ssl_key_gen_cmd = Mixlib::ShellOut.new(
      "openssl req -config #{node['bcpc']['ssl']['conf_file']} -extensions v3_req -new -x509 " \
      "-passout pass:temp_passwd -newkey rsa:#{node['bcpc']['ssl']['key_size']} " \
      "-out /dev/stdout -keyout /dev/stdout -days 1095 -subj \"#{subj_str}\""
    )
    ssl_key_gen_cmd.run_command
    raise "Generate ssl-private-key failed, #{ssl_key_gen_cmd.error}" if ssl_key_gen_cmd.error!
    # Chef::Log.info("ssl keypair generated. keypair = #{ssl_key_gen_cmd.stdout}")
    ssl_keypair = ssl_key_gen_cmd.stdout

    # Get the certificate (public key)
    ssl_certificate_cmd = Mixlib::ShellOut.new("echo \"#{ssl_keypair}\" | openssl x509")
    ssl_certificate_cmd.run_command
    raise "Obtain ssl-certificate failed, #{ssl_certificate_cmd.error}" if ssl_certificate_cmd.error!
    ssl_certificate = ssl_certificate_cmd.stdout
    # Chef::Log.info("ssl certificate generated. certificate = #{ssl_certificate}")

    # save certificate to data bag for public access
    make_config('ssl-certificate', ssl_certificate)

    # Get the private key
    ssl_private_key_cmd = Mixlib::ShellOut.new("echo \"#{ssl_keypair}\" | openssl rsa -passin pass:temp_passwd -out /dev/stdout")
    ssl_private_key_cmd.run_command
    raise "Obtain ssl-private-key failed, #{ssl_private_key_cmd.error}" if ssl_private_key_cmd.error!
    ssl_private_key = ssl_private_key_cmd.stdout
    # Chef::Log.info("ssl private key generated. key = #{ssl_private_key}")

    # pass to chef-vault
    node.run_state['new_ssl_private_key'] = ssl_private_key

    Chef::Log.info('Generate-ssh-keypair finished.')
  end
  only_if { get_config('ssl-certificate').nil? || get_config('private-key', 'ssl', 'os').nil? }
  notifies :create, 'chef_vault_secret[ssl]', :immediate
end

# save to chef-vault after new keypair is generated.
chef_vault_secret 'ssl' do
  data_bag 'os'
  raw_data(lazy { { 'private-key' => node.run_state['new_ssl_private_key'] } })
  admins "#{all_nodes},#{bootstrap}"
  search '*:*'
  action :nothing
end
