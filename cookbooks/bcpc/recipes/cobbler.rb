#
# Cookbook Name:: bcpc
# Recipe:: cobbler
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

gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s
rewind_version = '0.0.9'

#
# Move to installing chef-rewind via execute block to work around
# issue where version string is empty when combining gem_binary,
# version and options in the gem_package resource
#
execute 'gem_install_chef-rewind' do
  command gem_path + ' install chef-rewind -q --no-rdoc --no-ri -v "' \
    + rewind_version + "\" --clear-sources -s #{get_binary_server_url}"
  not_if gem_path + ' list chef-rewind -i -v "' + rewind_version + '"'
  action :nothing
  environment ({ 'no_proxy' => URI.parse(get_binary_server_url).host })
end.run_action(:run)

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
  action :create_if_missing
end

# The cobblerd cookbook relies on this attribute.
node.force_default[:cobblerd][:web_password] = web_password

bcpc_repo 'cobbler26'

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

service 'xinetd' do
  action [:enable, :start]

  if node[:lsb][:release] == 'trusty'
    ignore_failure true
  end

  subscribes :restart, 'bash[cobbler-sync]', :immediately
end

#
# Cobbler 2.6 expects to drop off a tftp configuration in
# /etc/xinetd.d, so we stop the independent tftp service ASAP.
#
service 'tftpd-hpa' do
  action [:stop, :disable]
end

apt_package 'cobbler' do
  action :install
  version '2.6.11-1'
  notifies :restart, 'service[xinetd]', :immediately
end

link '/tftpboot' do
  to '/var/lib/tftpboot'
end

[
  'proxy',
  'proxy_http'
].each do |mod_name|
  execute "a2enmod #{mod_name}" do
    not_if {
      File.exist?("/etc/apache2/mods-enabled/#{mod_name}.load")
    }
    #
    # We need to restart apache2 before any cobbler commands are run.
    # Restarting it multiple times is pretty harmless.
    #
    notifies :restart, 'service[apache2]', :immediately
  end
end

package 'isc-dhcp-server'

#
# The cobblerd cookbook assumes we use the Ubuntu 'universe'
# packages. Unlike "universe," the upstream packages include the
# cobbler-web material in the main package, so we do not need the
# second package.
#
# The "unwind" resource is no longer reliable under Chef 12.x, but
# the replacement for unwind is not available under Chef 11.x.  Until
# we can consilidate all nodes on 12.x, we're stuck doing this the
# hard way with equivs.
#
package 'equivs'

control_file_path =
  ::File.join(Chef::Config.file_cache_path, 'cobbler-web.control')

file control_file_path do
  content <<-EOM.gsub(/^ {4}/,'')
    Section: admin
    Priority: optional
    Standards-Version: 3.9.2

    Package: cobbler-web
    Version: 2.6.11-1
    Maintainer: BACH <hadoop@bloomberg.net>
    Architecture: all
    Description: Dummy package to prevent the installation of cobbler-web
  EOM
end

deb_file_path =
   ::File.join(Chef::Config.file_cache_path,'cobbler-web_2.6.11-1_all.deb')

execute 'cobbler-web-build' do
   cwd ::File.dirname(deb_file_path)
   command "equivs-build #{control_file_path}"
   creates deb_file_path
end

dpkg_package deb_file_path

include_recipe 'cobblerd::default'
include_recipe 'cobblerd::web'

#
# The cobblerd cookbook references the wrong service name. Upstream
# cobbler packages use 'cobblerd' instead of 'cobbler'
#
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
    #
    # We need to restart apache2 before any cobbler commands are run.
    # Restarting it multiple times is pretty harmless.
    #
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

template '/var/lib/cobbler/scripts/select_bach_root_disk' do
  source 'cobbler/select_bach_root_disk.erb'
  mode 0644
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
  action :import
end

cobbler_image 'ubuntu-14.04-mini' do
  source "#{get_binary_server_url}/ubuntu-14.04-hwe44-mini.iso"
  os_version 'trusty'
  os_breed 'ubuntu'
  action :import
end

{
  trusty: 'ubuntu-14.04-mini-x86_64',
  precise: 'ubuntu-12.04-mini-x86_64'
}.each do |version, distro_name|
  cobbler_profile "bcpc_host_#{version}" do
    kickstart "cobbler/#{version}.preseed"
    distro distro_name
    action :import
  end

  #
  # The biosdevname=0 and net.ifnames=0 kernel options are important
  # in order to force the use of old-fashioned eth0..ethN device
  # naming on Ubuntu 14.04.
  #
  # "Modern" naming schemes for network devices will break the bcpc
  # recipes for bonding.
  #
  execute 'set-ubuntu-kopts' do
    full_kopts =
      node[:bcpc][:bootstrap][:preseed][:add_kernel_opts] +
      " biosdevname=0 net.ifnames=0"

    command "cobbler distro edit " \
      "--name=#{distro_name} " \
      "--kopts='#{full_kopts}'"

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
    imgargs $kernel_name initrd=initrd.gz $append_line
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

# The "LOCALBOOT -1" statement does not seem to work reliably on VirtualBox.
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
  supports :status => true, :restart => true
  action [:enable,:start]
  notifies :run, 'bash[cobbler-sync]', :delayed
end

#
# After recurring problems with reloading the xinetd
# configuration, we resort to a forced restart on every chef run.
#
ruby_block 'xinetd-restart' do
  block do
    resources('service[xinetd]').run_action(:restart)
  end
end
