#
# Cookbook Name:: bcpc
# Recipe:: ssl_cert_deploy
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

# deploy ssl certificate and private key

ssl_cert = get_config('ssl-certificate')
# certificate
template node['bcpc']['ssl']['cert_file'] do
  source 'ssl-bcpc.crt.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables('ssl_certificate' => ssl_cert)
  notifies :run, 'execute[update-ca-certificates --fresh]', :immediately
end

cert_hash = OpenSSL::X509::Certificate.new(ssl_cert).subject.hash.to_s 16
execute 'update-ca-certificates --fresh' do
  action :nothing
  creates "/etc/ssl/certs/#{cert_hash}.0"
end

# private key
directory node['bcpc']['ssl']['key_file_dir'] do
  owner 'root'
  group 'root'
  mode 0o0700
end

template node['bcpc']['ssl']['key_file'] do
  source 'ssl-bcpc.key.erb'
  owner 'root'
  group 'root'
  mode 0o0600
  variables('ssl_private_key' => get_config('private-key', 'ssl', 'os'))
end

# verify if public and private key matches
ruby_block 'verify-ssl-keypair' do
  block do
    # get public key sha256sum
    pub_sha_cmd = Mixlib::ShellOut.new("openssl x509 -in #{node['bcpc']['ssl']['cert_file']} -pubkey -noout -outform pem | sha256sum")
    pub_sha_cmd.run_command
    raise "Get sha256sum for ssl-public-key failed, #{pub_sha_cmd.error}" if pub_sha_cmd.error!
    pub_sha = pub_sha_cmd.stdout
    Chef::Log.info("ssl public key sha256sum = #{pub_sha}")

    # get private key sha256sum
    pri_sha_cmd = Mixlib::ShellOut.new("openssl pkey -in #{node['bcpc']['ssl']['key_file']} -pubout -outform pem | sha256sum")
    pri_sha_cmd.run_command
    raise "Get sha256sum for ssl-private-key failed, #{pri_sha_cmd.error}" if pri_sha_cmd.error!
    pri_sha = pri_sha_cmd.stdout
    Chef::Log.info("ssl private key sha256sum = #{pri_sha}")

    # check if they match
    raise "ssl public and private keypair doesn't match, pub = #{pub_sha}, pri = #{pri_sha}" if pub_sha != pri_sha
    Chef::Log.info("ssl public and private keypair matches.")
  end
end
