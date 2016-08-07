#
# Cookbook Name:: bcpc
# Recipe:: cobbler
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

chef_gem 'chef-rewind'

require 'digest/sha2'
require 'chef/rewind'
require 'chef-vault'

make_config('cobbler-web-user', 'cobbler')

create_databag('os')

# TODO: Don't generate passwords at compile time.
web_password = get_config('cobbler-web-password')
web_password = secure_password if web_password.nil?

root_password = get_config('cobbler-root-password')
root_password = secure_password if root_password.nil?

root_password_salted = root_password.crypt('$6$' + rand(36**8).to_s(36))

chef_vault_secret 'cobbler' do
  data_bag 'os'
  raw_data('web-password' => web_password,
           'root-password' => root_password,
           'root-password-salted' => root_password_salted)
  admins node[:fqdn]
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

node.set[:cobbler][:web_username] =
  get_config('cobbler-web-user')
node.set[:cobbler][:web_password] =
  get_config('web-password', 'cobbler', 'os')

# # This apt repository is signed with an expired key.
# apt_repository 'cobbler26' do
#   uri node[:bcpc][:repos][:cobbler26]
#   distribution nil
#   components [ '/' ]
#   key 'cobbler26-release.key'
# end

# Until cobbler updates their apt repository, we'll just download and
# install it the old-fashioned way.
cobbler_filename = 'cobbler_2.6.11-1_all.deb'
cobbler_deb_path = File.join(Chef::Config[:file_cache_path], cobbler_filename)

remote_file cobbler_deb_path do
  source node[:bcpc][:repos][:cobbler26] + '/all/' + cobbler_filename
  checksum 'c881a4502bc79c318d93920206734a1ab7da2dcb07dbd5bf6d6befab5b0d79c3'
end

[
  'python',
  'apache2',
  'libapache2-mod-wsgi',
  'python-support',
  'python-yaml',
  'python-netaddr',
  'python-cheetah',
  'debmirror',
  'syslinux',
  'python-simplejson',
  'python-urlgrabber',
  'python-django',
  'tftp-hpa',
  'tftpd-hpa',
  'xinetd'
].each do |package_name|
  package package_name do
    action :upgrade
  end
end

#
# Cobbler 2.6 expects to drop off a tftp configuration in
# /etc/xinetd.d, so we stop the independent tftp service ASAP.
#
service 'tftpd-hpa' do
  action [:stop, :disable]
end

link '/tftpboot' do
  to '/var/lib/tftpboot'
end

service 'xinetd' do
  action :enable
  subscribes :restart, 'bash[cobbler-sync]'
end

[
  'proxy',
  'proxy_http'
].each do |mod_name|
  execute "a2enmod #{mod_name}" do
    not_if {
      File.exist?("/etc/apache2/mods-enabled/#{mod_name}.load")
    }
    # We need to restart apache2 before any cobbler commands are run.
    # Restarting it multiple times is pretty harmless.
    notifies :restart, 'service[apache2]', :immediately
  end
end

dpkg_package cobbler_deb_path do
  not_if 'dpkg -s cobbler && dpkg -s cobbler | grep 2.6.11-1'
end

package 'isc-dhcp-server'

include_recipe 'cobblerd::web'

# The cobblerd cookbook assumes we use the Ubuntu 'universe'
# packages. Unlike "universe," the upstream packages include the
# cobbler-web material in the main package, so we do not need the
# second package resource.
unwind 'package[cobbler-web]'

# The cobblerd cookbook references the wrong service name. Upstream
# cobbler packages use 'cobblerd' instead of 'cobbler'
rewind 'service[cobbler]' do
  service_name 'cobblerd'
end

template '/etc/apache2/conf.d/cobbler.conf' do
  source 'cobbler/apache.conf.erb'
  mode 00644
end

['cobbler.conf', 'cobbler_web.conf'].each do |conf_file|
  link "/etc/apache2/conf-enabled/#{conf_file}" do
    to "/etc/apache2/conf.d/#{conf_file}"
    # We need to restart apache2 before any cobbler commands are run.
    # Restarting it multiple times is pretty harmless.
    notifies :restart, 'service[apache2]', :immediately
  end
end

template '/etc/cobbler/settings' do
  source 'cobbler/settings.erb'
  mode 0644
  notifies :restart, 'service[cobbler]', :immediately
end

template '/etc/cobbler/dhcp.template' do
  source 'cobbler/dhcp.template.erb'
  mode 0644
  variables(subnets: node[:bcpc][:networks])
  notifies :run, 'bash[cobbler-sync]', :delayed
end

cookbook_file '/var/lib/cobbler/loaders/ipxe-x86_64.efi' do
  source 'ipxe-x86_64.efi'
  mode 0644
  notifies :run, 'bash[cobbler-sync]', :delayed
end

link '/var/lib/tftpboot/ipxe-x86_64.efi' do
  to '/var/lib/cobbler/loaders/ipxe-x86_64.efi'
  link_type :hard
end

link '/var/lib/tftpboot/chain.c32' do
  to '/usr/lib/syslinux/chain.c32'
  link_type :hard
end

cobbler_image 'ubuntu-12.04-mini' do
  source "#{get_binary_server_url}/ubuntu-12.04-hwe313-mini.iso"
  os_version 'precise'
  os_breed 'ubuntu'
end

cobbler_image 'ubuntu-14.04-mini' do
  source "#{get_binary_server_url}/ubuntu-14.04-hwe44-mini.iso"
  os_version 'trusty'
  os_breed 'ubuntu'
end

{
  trusty: 'ubuntu-14.04-mini-x86_64',
  precise: 'ubuntu-12.04-mini-x86_64'
}.each do |version, distro_name|
  cobbler_profile "bcpc_host_#{version}" do
    kickstart "cobbler/#{version}.preseed"
    distro distro_name
  end

  execute 'set-ubuntu-kopts' do
    command "cobbler distro edit " \
      "--name=#{distro_name} " \
      "--kopts=#{node[:bcpc][:bootstrap][:preseed][:add_kernel_opts]}"
    notifies :run, 'bash[cobbler-sync]', :delayed
  end
end
#
# When PXE booting an EFI host, the kernel will require an explicit
# filename for the initrd. As far as I can tell, the filename is
# relative to the kernel path.
#
# Unfortunately 'cobbler distro edit --kopts' will not allow you to
# add an initrd option to the append_line, so we have to edit the gpxe
# script directly.
#
# For Ubuntu 14.04, this means appending "initrd=initrd.gz" to the
# kernel argument list.  This template will break non-Ubuntu installs,
# because different distributions use different filenames for the
# compressed initrd.
#
file '/etc/cobbler/pxe/gpxe_system_linux.template' do
  content <<-EOM.gsub(/^ {4}/, '')
    #!gpxe
    #
    # This file was generated by Chef.
    # Local changes will be reverted.
    #
    kernel http://$server:$http_port/cobbler/images/$distro/$kernel_name
    imgargs $kernel_name $append_line initrd=initrd.gz
    initrd http://$server:$http_port/cobbler/images/$distro/$initrd_name
    boot
  EOM
  mode 0444
  notifies :run, 'bash[cobbler-sync]', :delayed
end

#
# The 'sanboot' verb is not supported on EFI, so we need to have the
# local disk template just exit the iPXE UEFI application.
#
file '/etc/cobbler/pxe/gpxe_system_local.template' do
  content <<-EOM.gsub(/^ {4}/, '')
    #!gpxe
    #
    # This file was generated by Chef.
    # Local changes will be reverted.
    #
    iseq ${platform} efi && exit

    iseq ${smbios/manufacturer} HP && exit ||
    sanboot --no-describe --drive 0x80
  EOM
  mode 0444
  notifies :run, 'bash[cobbler-sync]', :delayed
end

#
# The "LOCALBOOT -1" does not seem to work reliably on VirtualBox.
#
file '/etc/cobbler/pxe/pxelocal.template' do
  content <<-EOM.gsub(/^ {4}/, '')
    DEFAULT local
    PROMPT 0
    TIMEOUT 0
    TOTALTIMEOUT 0
    ONTIMEOUT local

    LABEL local
        KERNEL chain.c32
  EOM
  mode 0444
  notifies :run, 'bash[cobbler-sync]', :delayed
end


service 'isc-dhcp-server' do
  #
  # We :enable instead of :start because Ubuntu 14.04 upstart returns
  # '1' when a service is already running, which aborts the chef run.
  #
  # 'cobbler sync' will start/restart the service in any case.
  #
  action [:enable]
  notifies :run, 'bash[cobbler-sync]', :delayed
end
