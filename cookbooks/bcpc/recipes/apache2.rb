#
# Cookbook Name:: bcpc
# Recipe:: apache2
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

package 'apache2' do
  action :upgrade
end

package 'libapache2-mod-fastcgi' do
  action :upgrade
end

%w(libapache2-mod-wsgi libapache2-mod-python libapache2-mod-php5).each do |pkg|
  package pkg do
    action :upgrade
  end
end

#
# Ubuntu 14.04's Apache has mod_version baked-in.
# Older versions of Apache have to have mod_version explicitly enabled.
#
if Gem::Version.new(node[:lsb][:release]) < Gem::Version.new('14.04')
  execute 'a2enmod version'
end

%w(ssl wsgi python php5 proxy_http rewrite).each do |mod|
  bash "apache-enable-#{mod}" do
    user 'root'
    code "a2enmod #{mod}"
    not_if "test -r /etc/apache2/mods-enabled/#{mod}.load"
    notifies :restart, 'service[apache2]', :delayed
  end
end

directory '/etc/apache2/vhost-root.d' do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

directory '/etc/apache2/vhost-ssl-root.d' do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

template '/etc/apache2/vhost-root.d/000-default.conf' do
  source 'apache-vhost-root-000-default.conf.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  notifies :restart, 'service[apache2]', :delayed
end

template '/etc/apache2/vhost-ssl-root.d/000-default.conf' do
  source 'apache-vhost-ssl-root-000-default.conf.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  notifies :restart, 'service[apache2]', :delayed
end

template '/etc/apache2/sites-enabled/000-default' do
  source 'apache-000-default.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  notifies :restart, 'service[apache2]', :delayed
end

bash 'set-apache-bind-address' do
  code <<-EOH
    sed -i "s/\\\(^[\\\t ]*Listen[\\\t ]*\\\)80[\\\t ]*$/\\\\1#{node[:bcpc][:management][:ip]}:80/g" /etc/apache2/ports.conf
    sed -i "s/\\\(^[\\\t ]*Listen[\\\t ]*\\\)443[\\\t ]*$/\\\\1#{node[:bcpc][:management][:ip]}:443/g" /etc/apache2/ports.conf
  EOH
  not_if "grep #{node[:bcpc][:management][:ip]} /etc/apache2/ports.conf"
  notifies :restart, 'service[apache2]', :immediately
end

service 'apache2' do
  action [:enable, :start]
  supports [:start, :stop, :restart, :status, :reload]
end

template '/var/www/index.html' do
  source 'index.html.erb'
  owner 'root'
  group 'root'
  mode 0o0644
end

# bach web document root
directory node['bcpc']['bach_web']['document_root'].to_s do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

# bach web configs
template '/etc/apache2/sites-available/bach-web.conf' do
  source 'bach-web.conf.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables(
    'host_ip'       => node['bcpc']['floating']['ip'],
    'host_port'     => node['bcpc']['bach_web']['port'],
    'document_root' => node['bcpc']['bach_web']['document_root'],
    'json_url'      => node['bcpc']['bach_web']['json_url'],
    'json_file'     => node['bcpc']['bach_web']['json_file']
  )
  notifies :restart, 'service[apache2]', :delayed
end

# A portal html pages for useful links
template "#{node['bcpc']['bach_web']['document_root']}/#{node['bcpc']['bach_web']['html_file']}" do
  source 'bach.html.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  variables(
    'cluster_name'  => node.chef_environment,
    'services'      => node['bcpc']['bach_web']['services'],
    'links'         => node['bcpc']['bach_web']['links'],
    'files'         => node['bcpc']['bach_web']['files']
  )
  notifies :restart, 'service[apache2]', :delayed
end

# A json files that expose the configs for easier consumption programatically.
# NOTE: node['bcpc']['bach_web'] should NOT contain anything sensitive or confidential
#       otherwise a dedicated hash should be used
file "#{node['bcpc']['bach_web']['document_root']}/#{node['bcpc']['bach_web']['json_file']}" do
  content Chef::JSONCompat.to_json_pretty(node['bcpc']['bach_web'].to_hash)
end


directory "#{node['bcpc']['bach_web']['document_root']}/files" do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

# enable bach-web
bash 'enable_bach_web' do
  user 'root'
  code 'a2ensite bach-web'
  not_if 'test -r /etc/apache2/sites-enabled/bach-web.conf'
  notifies :restart, 'service[apache2]', :delayed
end
