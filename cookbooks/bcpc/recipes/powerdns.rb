#
# Cookbook Name:: bcpc
# Recipe:: powerdns
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

make_config('mysql-pdns-user', 'pdns')

mysql_pdns_password = get_config('password', 'mysql-pdns', 'os')
if mysql_pdns_password.nil?
  mysql_pdns_password = secure_password
end

pdns_admins = (get_head_node_names + [get_bootstrap]).join(',')

#
# For some reason, we are compelled to specify a provider.
# This will probably break if we ever move to chef-vault cookbook 2.x
#
chef_vault_secret "mysql-pdns" do
  provider ChefVaultCookbook::Provider::ChefVaultSecret
  data_bag 'os'
  raw_data({ 'password' => mysql_pdns_password })
  admins pdns_admins
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

subnet = node[:bcpc][:management][:subnet]
raise "Did not get a subnet" if not subnet

if node[:bcpc][:management][:vip] and get_nodes_for("mysql").length() > 0

  allnodes = Array.new
  get_all_nodes.each do |nodeobj|
    tempHash = Hash.new
    tempHash['hostname'] = nodeobj.hostname
    tempHash['management_ip'] = nodeobj.bcpc.management.ip
    tempHash['storage_ip'] = nodeobj.bcpc.storage.ip
    tempHash['floating_ip'] = nodeobj.bcpc.floating.ip
    allnodes.push(tempHash)
  end

  if !node[:bcpc][:management][:viphost].nil?
    tempHash = Hash.new
    tempHash['hostname'] = node[:bcpc][:management][:viphost].split('.')[0]
    tempHash['management_ip'] = node[:bcpc][:management][:vip]
    tempHash['floating_ip'] =  node[:bcpc][:floating][:vip]
    tempHash['storage_ip'] =  node[:bcpc][:management][:vip]
    allnodes.push(tempHash)
  end

  node.default['pdns']['authoritative']['package']['backends'] = ['gmysql']
  node.default['pdns']['authoritative']['config']['disable_axfr'] = false
  node.default['pdns']['authoritative']['config']['launch'] = 'gmysql'

  node.default['pdns']['authoritative']['gmysql'].tap do |config|
    config['gmysql-host'] = node[:bcpc][:management][:vip]
    config['gmysql-port'] = 3306
    config['gmysql-user'] = get_config!('mysql-pdns-user')
    config['gmysql-password'] = get_config!('password', 'mysql-pdns', 'os')
    config['gmysql-dbname'] = node['bcpc']['pdns_dbname']
    config['gmysql-dnssec'] = 'no'
  end

  include_recipe 'bcpc::mysql_client'

  mysql_connection_info = lambda do
    {
     :host => node['pdns']['authoritative']['gmysql']['gmysql-host'],
     :port => node['pdns']['authoritative']['gmysql']['gmysql-port'],
     :username => 'root',
     :password => get_config!('password','mysql-root','os')
    }
  end

  mysql_database node['bcpc']['pdns_dbname'] do
    connection lazy { mysql_connection_info.call }
    notifies :run, 'execute[install-pdns-schema]', :immediately
  end

  mysql_database_user get_config!('mysql-pdns-user') do
    connection lazy { mysql_connection_info.call }
    password get_config!('password', 'mysql-pdns', 'os')
    action :create
    notifies :reload, 'service[pdns]'
  end

  mysql_database_user get_config!('mysql-pdns-user') do
    connection lazy { mysql_connection_info.call }
    database_name node['bcpc']['pdns_dbname']
    host '%'
    privileges [:all]
    action :grant
    notifies :reload, 'service[pdns]'
  end

  include_recipe 'pdns::authoritative_package'
  delete_resource(:gem_package, 'mysql2')
  delete_resource(:gem_package, 'sequel')

  #
  # This schema file works great when installed via the mysql CLI, but
  # it fails when Ruby reads it and feeds via a query resource.  This
  # smells like an escaping problem.
  #
  # For now, the query resource has been replaced with an 'execute'
  # resource that invokes the mysql CLI.
  #
  schema_path = '/usr/share/dbconfig-common/data/pdns-backend-mysql/install/mysql'

  mysql_command_string = lambda do
    "/usr/bin/mysql -u root " +
      "--host=#{node['pdns']['authoritative']['config']['gmysql-host']} " +
      "--password='#{get_config!('password','mysql-root','os')}' pdns"
  end

  execute 'install-pdns-schema' do
    command lazy {
      "cat #{schema_path} | " +
      "perl -nle 's/type=Inno/engine=Inno/g; print' | " +
      mysql_command_string.call
    }
    not_if {
      c = Mixlib::ShellOut.new('echo "select id from domains limit 1;" | ' +
                               mysql_command_string.call)
      c.run_command
      c.status.success?
    }
    sensitive true if respond_to?(:sensitive)
    notifies :reload, 'service[pdns]'
  end

end

node.default['pdns']['authoritative']['config']['recursor'] =
  node[:bcpc][:dns_servers][0]

node.default['pdns']['authoritative']['config']['local_address'] = [ node[:bcpc][:floating][:vip] , node[:bcpc][:management][:vip] ]

include_recipe 'pdns::authoritative_package'

reverse_dns_zone = node['bcpc']['networks'][subnet]['floating']['reverse_dns_zone'] || calc_reverse_dns_zone(node['bcpc']['networks'][subnet]['floating']['cidr'])

Chef::Log.info("Reverse DNS zone: #{reverse_dns_zone}")

pdns_domain node[:bcpc][:domain_name] do
  soa_ip node[:bcpc][:floating][:vip]
end

pdns_domain reverse_dns_zone  do
  soa_ip node[:bcpc][:floating][:vip]
end

domain_name = node[:bcpc][:domain_name]
allnodes.each do |server|
  management_ip = server['management_ip']
  floating_ip = server['floating_ip']
  storage_ip = server['storage_ip']
  hostname = server['hostname']

  ruby_block "create-dns-entry-#{hostname}" do
    block do
      # check if we have a float address
      if management_ip != floating_ip then
        float_name = float_host(hostname) + '.' + domain_name

        fwdR = Chef::Resource::PdnsRecord.new(float_name, run_context)
        fwdR.domain(domain_name)
        fwdR.content(floating_ip)
        fwdR.type('A')
        fwdR.ttl(300)
        fwdR.run_action(:create)

        # Create reverse record
        revR = Chef::Resource::PdnsRecord.new(calc_reverse_ip_address(floating_ip),
                                           run_context)
        revR.domain(reverse_dns_zone)
        revR.content(float_name)
        revR.type('PTR')
        revR.ttl(300)
        revR.run_action(:create)
      end

      # check if we have a storage address
      if management_ip != storage_ip then
        storage_name =
          storage_host(hostname) + '.' + domain_name

        fwdR = Chef::Resource::PdnsRecord.new(storage_name, run_context)

        fwdR.domain(domain_name)
        fwdR.content(storage_ip)
        fwdR.type('A')
        fwdR.ttl(300)
        fwdR.run_action(:create)

        # Create reverse record
        revR = Chef::Resource::PdnsRecord.new(calc_reverse_ip_address(storage_ip),
                                           run_context)
        revR.domain(reverse_dns_zone)
        revR.content(storage_name)
        revR.type('PTR')
        revR.ttl(300)
        revR.run_action(:create)
      end

      if management_ip
        # add a record for the management IP
        management_name = hostname + '.' + domain_name
        fwdR = Chef::Resource::PdnsRecord.new(management_name, run_context)
        fwdR.domain(domain_name)
        fwdR.content(management_ip)
        fwdR.type('A')
        fwdR.ttl(300)
        fwdR.run_action(:create)

        # Create reverse record
        revR = Chef::Resource::PdnsRecord.new(calc_reverse_ip_address(management_ip),
                                           run_context)
        revR.domain(reverse_dns_zone)
        revR.content(management_name)
        revR.type('PTR')
        revR.ttl(300)
        revR.run_action(:create)
      else
        Chef::Log.warn("No IP address found for host #{hostname}!")
      end
    end
  end
end
