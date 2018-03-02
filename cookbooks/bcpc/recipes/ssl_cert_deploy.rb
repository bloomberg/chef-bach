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

# certificate
template node['bcpc']['ssl']['cert_file'] do
  source 'ssl-bcpc.crt.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables('ssl_certificate' => get_config('ssl-certificate'))
  notifies :run, 'ruby_block[update-cacertificate-list]', :immediately
end

ruby_block 'update-cacertificate-list' do
  block do
    Chef::Log.info('Updating ca-certificate list')
    ca_certs_update_cmd = Mixlib::ShellOut.new('sudo update-ca-certificates')
    ca_certs_update_cmd.run_command
    raise "Updating ca-certificate list failed, #{ca_certs_update_cmd.error}" if ca_certs_update_cmd.error!
    Chef::Log.info('Updating ca-certificate returned #{ca_certs_update_cmd.stdout')

    # verify if the certificate is in the list
    # after update-ca-certificates is called a symb link will be created
    # /etc/ssl/certs/ssl-bcpc.pem -> /usr/local/share/ca-certificates/ssl-bcpc.crt
    # TODO: may need more precise grep, e.g. the whole Issuer line, or SubjectAlternativeName
    cacert_verify_cmd = Mixlib::ShellOut.new('keytool -printcert -file /etc/ssl/certs/ca-certificates.crt ' \
      "| grep #{node['bcpc']['organization']}")
    cacert_verify_cmd.run_command
    raise "verify ca-certificate list failed, #{cacert_verify_cmd.error}" if cacert_verify_cmd.error!
    Chef::Log.info('Updating ca-certificate list finished.')
  end
  notifies :restart, 'service[apache2]', :delayed if File.exist?("/etc/init.d/apache2")
  action :nothing
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
