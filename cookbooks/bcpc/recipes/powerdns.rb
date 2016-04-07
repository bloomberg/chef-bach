#
# Cookbook Name:: bcpc
# Recipe:: powerdns
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

#
# If we have a BCPC MySQL cluster, we'll use that for PowerDNS, and
# all nodes will share it.
#
# Otherwise, this recipe will configure an independent SQLite-backed
# PDNS on each node on which it is run.  Since Chef inserts all
# cluster-internal records, at least those records will remain in sync
# without sharing storage.
#
if node[:bcpc][:management][:vip] and get_nodes_for("mysql").length() > 0
  make_bcpc_config('mysql-pdns-user', "pdns")
  make_bcpc_config('mysql-pdns-password', secure_password)

  bootstrap = get_bootstrap
  results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
  nodes = results == "" ? node['fqdn'] : results

  node.set['pdns']['authoritative']['package']['backends'] = ['gmysql']
  node.set['pdns']['authoritative']['config']['disable_axfr'] = false
  node.set['pdns']['authoritative']['config']['launch'] = 'gmysql'

  node.set['pdns']['authoritative']['gmysql'].tap do |config|
    config['gmysql-host'] = node[:bcpc][:management][:vip]
    config['gmysql-port'] = 3306
    config['gmysql-user'] = get_bcpc_config!('mysql-pdns-user')
    config['gmysql-password'] = get_bcpc_config!('mysql-pdns-password')
    config['gmysql-dbname'] = node['bcpc']['pdns_dbname']
   # config['gmysql-dnssec'] = 'yes'
    config['gmysql-dnssec'] = 'false'
  end

  package 'libmysqlclient-dev'

  chef_gem 'mysql2' do
    compile_time false
  end

  mysql_connection_info = lambda do
    {
     :host => node['pdns']['authoritative']['gmysql']['gmysql-host'],
     :port => node['pdns']['authoritative']['gmysql']['gmysql-port'],
     :username => 'root',
     :password => get_bcpc_config!('mysql-root-password')
    }
  end

  mysql_database node['bcpc']['pdns_dbname'] do
    connection lazy { mysql_connection_info.call }
    notifies :run, 'execute[install-pdns-schema]', :immediately
  end

  mysql_database_user get_bcpc_config!('mysql-pdns-user') do
    connection lazy { mysql_connection_info.call }
    password get_bcpc_config!('mysql-pdns-password')
    action :create
    notifies :reload, 'service[pdns]'
  end

  mysql_database_user get_bcpc_config!('mysql-pdns-user') do
    connection lazy { mysql_connection_info.call }
    database_name node['bcpc']['pdns_dbname']
    host '%'
    privileges [:all]
    action :grant
    notifies :reload, 'service[pdns]'
  end

  include_recipe 'pdns::authoritative_package'

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
      "--password='#{get_bcpc_config!('mysql-root-password')}' pdns"
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

   sensitive true

    notifies :reload, 'service[pdns]'
  end

end

node.set['pdns']['authoritative']['config']['recursor'] =
  node[:bcpc][:dns_servers][0]

# mkoni need to set local_address to mgmt and floating VIPs
#node.set['pdns']['recursor']['config']['local_address'] =

include_recipe 'pdns::authoritative_package'

reverse_dns_zone = node['bcpc']['floating']['reverse_dns_zone'] || calc_reverse_dns_zone(node['bcpc']['floating']['cidr'])

Chef::Log.info("Reverse DNS zone: #{reverse_dns_zone}")

pdns_domain node[:bcpc][:domain_name] do
  soa_ip node[:bcpc][:floating][:vip]
end

get_all_nodes.each do |server|
  ruby_block "create-dns-entry-#{server['hostname']}" do
    block do
      # check if we have a float address
      if server['bcpc']['management']['ip'] != server['bcpc']['floating']['ip'] then
        float_name =
          float_host(server['hostname']) + '.' + node[:bcpc][:domain_name]
        
        r = Chef::Resource::PdnsRecord.new(float_name,
                                           run_context)
        r.domain(node[:bcpc][:domain_name])
        r.content(server[:bcpc][:floating][:ip])
        r.type('A')
        r.ttl(300)
        r.run_action(:create)
      end

      # check if we have a storage address
      if server['bcpc']['management']['ip'] != server['bcpc']['storage']['ip'] then
        storage_name =
          storage_host(server['hostname']) + '.' + node[:bcpc][:domain_name]
        
        r = Chef::Resource::PdnsRecord.new(storage_name,
                                           run_context)
        r.domain(node[:bcpc][:domain_name])
        r.content(server[:bcpc][:storage][:ip])
        r.type('A')
        r.ttl(300)
        r.run_action(:create)
      end

      if server['bcpc']['management']['ip']
        # add a record for the management IP
        management_name = server['hostname'] + '.' + node[:bcpc][:domain_name]
        r = Chef::Resource::PdnsRecord.new(management_name,
                                           run_context)
        r.domain(node[:bcpc][:domain_name])
        r.content(server['bcpc']['management']['ip'])
        r.type('A')
        r.ttl(300)
        r.run_action(:create)
      else
        Chef::Log.warn("No IP address found for host #{server['hostname']}!")
      end
    end
  end
end
