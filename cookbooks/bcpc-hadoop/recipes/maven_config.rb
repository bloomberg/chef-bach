#
# Cookbook Name:: bcpc-hadoop
# Recipe:: maven_config
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

maven_file = Pathname.new(node['maven']['url']).basename

# Dependencies of the maven cookbook.
%w(gyoku nori).each do |gem_name|
  bcpc_chef_gem gem_name do
    compile_time true
  end
end

# handling for custom SSL certificates
cert_dir = '/usr/local/share/ca-certificates'
custom_certs = ::Find.find(cert_dir).select { |f| ::File.file?(f) } \
  if ::Dir.exist?(cert_dir)

include_recipe 'bcpc::proxy_configuration' if node['bcpc']['bootstrap']['proxy']

# download Maven only if not already stashed in the bins directory
if node['fqdn'] == get_bootstrap
  internet_download_url = node['maven']['url']
  remote_file "/home/vagrant/chef-bcpc/bins/#{maven_file}" do
    source internet_download_url
    action :create
    mode 0o0555
    checksum node['maven']['checksum']
  end
else
  node.override['maven']['url'] = File.join(get_binary_server_url, maven_file)
end

include_recipe 'maven::default'

file 'keystore file' do
  path node['bcpc']['hadoop']['java_https_keystore']
  action :nothing
end

unless ::File.exist?(node['bcpc']['hadoop']['java_https_keystore'])
  custom_certs.map do |cert|
    execute "create keystore #{::File.basename(cert)}" do
      command <<-EOH
        yes | keytool -v -alias #{::File.basename(cert)} -import \
        -file #{cert} \
        -keystore #{node['bcpc']['hadoop']['java_https_keystore']} \
        -storepass changeit \
        -trustcacerts \
      EOH
    not_if "keytool -alias #{::File.basename(cert)} -list -file #{cert} \
      -keystore #{node['bcpc']['hadoop']['java_https_keystore']} \
      -storepass changeit"
    end
  end
end

unless custom_certs.empty?
  node.override['maven']['mavenrc']['opts'] = <<-EOH
    #{node['maven']['mavenrc']['opts']} \
    -Djavax.net.ssl.trustStore=#{node['bcpc']['hadoop']['java_https_keystore']} \
    -Djavax.net.ssl.trustStorePassword=changeit
  EOH
end

# Setup custom maven config
directory '/root/.m2' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

include_recipe 'maven::settings'

unless node['bcpc']['bootstrap']['proxy'].nil?
  maven_settings 'settings.proxies' do
    uri = URI(node['bcpc']['bootstrap']['proxy'])
    value proxy: {
      active: true,
      protocol: uri.scheme,
      host: uri.host,
      port: uri.port,
      nonProxyHosts: node['bcpc']['no_proxy'].join('|')
    }
  end
end

# it looks like the Maven cookbook uses the default
# restrictive umask from Chef-Client
execute 'chmod maven' do
  command "chmod -R 755 #{node['maven']['m2_home']}"
end
