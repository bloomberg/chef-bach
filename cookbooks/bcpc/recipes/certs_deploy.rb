#
# Cookbook Name:: bcpc
# Recipe:: certs_depoly
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

# Get ssh and ssl key pairs and deploy

# ------------------------ SSH -----------------------
#get_config('ssh-public-key')
#get_config('ssh-private-key', 'ssh-keypair', 'os')

# public key
directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode 0o0700
end

template '/root/.ssh/authorized_keys' do
  source 'authorized_keys.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables('ssh_public_key' => get_config('ssh-public-key'))
end

# private key
template '/root/.ssh/id_rsa' do
  source 'id_rsa.erb'
  owner 'root'
  group 'root'
  mode 0o0600
  variables('ssh_private_key' => get_config('ssh-private-key', 'ssh-keypair', 'os'))
end

# ------------------------ SSL -----------------------
#get_config('ssl-certificate')
#get_config('ssl-private-key', 'ssl-keypair', 'os')

# certificate (public key)
template "/etc/ssl/certs/ssl-bcpc.pem" do
    source "ssl-bcpc.pem.erb"
    owner "root"
    group "root"
    mode 00644
  variables('ssl_certificate' => get_config('ssl-certificate'))
end

# private key
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
  variables('ssl_private_key' => get_config('ssl-private-key', 'ssl-keypair', 'os'))
end
