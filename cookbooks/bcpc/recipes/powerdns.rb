#
# Cookbook Name:: bcpc
# Recipe:: powerdns
#
# Copyright 2013, Bloomberg L.P.
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

include_recipe "bcpc::nova-head"

ruby_block "initialize-powerdns-config" do
    block do
        make_config('mysql-pdns-user', "pdns")
        make_config('mysql-pdns-password', secure_password)
    end
end

%w{pdns-server pdns-backend-mysql}.each do |pkg|
    package pkg do
        action :upgrade
    end
end

template "/etc/powerdns/pdns.conf" do
    source "pdns.conf.erb"
    owner "root"
    group "root"
    mode 00600
    notifies :restart, "service[pdns]", :delayed
end

template "/etc/powerdns/pdns.d/pdns.local.gmysql" do
    source "pdns.local.gmysql.erb"
    owner "pdns"
    group "root"
    mode 00640
    notifies :restart, "service[pdns]", :delayed
end

ruby_block "powerdns-database-creation" do
    block do
        if not system "mysql -uroot -p#{get_config('mysql-root-password')} -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"#{node['bcpc']['pdns_dbname']}\"'|grep \"#{node['bcpc']['pdns_dbname']}\"" then
            %x[ mysql -uroot -p#{get_config('mysql-root-password')} -e "CREATE DATABASE #{node['bcpc']['pdns_dbname']};"
                mysql -uroot -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node['bcpc']['pdns_dbname']}.* TO '#{get_config('mysql-pdns-user')}'@'%' IDENTIFIED BY '#{get_config('mysql-pdns-password')}';"
                mysql -uroot -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node['bcpc']['pdns_dbname']}.* TO '#{get_config('mysql-pdns-user')}'@'localhost' IDENTIFIED BY '#{get_config('mysql-pdns-password')}';"
                mysql -uroot -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node['bcpc']['nova_dbname']}.* TO '#{get_config('mysql-pdns-user')}'@'%' IDENTIFIED BY '#{get_config('mysql-pdns-password')}';"
                mysql -uroot -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node['bcpc']['nova_dbname']}.* TO '#{get_config('mysql-pdns-user')}'@'localhost' IDENTIFIED BY '#{get_config('mysql-pdns-password')}';"
                mysql -uroot -p#{get_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
            ]
            self.notifies :restart, "service[pdns]", :delayed
            self.resolve_notification_references
        end
    end
end

ruby_block "powerdns-table-domains" do
    block do
        if not system "mysql -uroot -p#{get_config('mysql-root-password')} -e 'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"#{node['bcpc']['pdns_dbname']}\" AND TABLE_NAME=\"domains\"'|grep \"domains\"" then
            %x[ mysql -uroot -p#{get_config('mysql-root-password')} #{node['bcpc']['pdns_dbname']} <<-EOH
                CREATE TABLE IF NOT EXISTS domains (
                    id INT auto_increment,
                    name VARCHAR(255) NOT NULL,
                    master VARCHAR(128) DEFAULT NULL,
                    last_check INT DEFAULT NULL,
                    type VARCHAR(6) NOT NULL,
                    notified_serial INT DEFAULT NULL,
                    account VARCHAR(40) DEFAULT NULL,
                    primary key (id)
                );
                CREATE UNIQUE INDEX name_index ON domains(name);
                INSERT INTO domains (name, type) values ('#{node[:bcpc][:domain_name]}', 'NATIVE');
            ]
            self.notifies :restart, "service[pdns]", :delayed
            self.resolve_notification_references
        end
    end
end

ruby_block "powerdns-table-records" do
    block do
        if not system "mysql -uroot -p#{get_config('mysql-root-password')} -e 'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"#{node['bcpc']['pdns_dbname']}\" AND TABLE_NAME=\"records_static\"'|grep \"records_static\"" then
            %x[ mysql -uroot -p#{get_config('mysql-root-password')} #{node['bcpc']['pdns_dbname']} <<-EOH

                    CREATE TABLE records_static (
                        id INT auto_increment,
                        domain_id INT DEFAULT NULL,
                        name VARCHAR(255) DEFAULT NULL,
                        type VARCHAR(6) DEFAULT NULL,
                        content VARCHAR(255) DEFAULT NULL,
                        ttl INT DEFAULT NULL,
                        prio INT DEFAULT NULL,
                        change_date INT DEFAULT NULL,
                        primary key(id)
                    );
                    INSERT INTO records_static (domain_id, name, content, type, ttl, prio) VALUES ((SELECT id FROM domains WHERE name='#{node[:bcpc][:domain_name]}'),'#{node[:bcpc][:domain_name]}','localhost root@#{node[:bcpc][:domain_name]} 1','SOA',300,NULL);
                    INSERT INTO records_static (domain_id, name, content, type, ttl, prio) VALUES ((SELECT id FROM domains WHERE name='#{node[:bcpc][:domain_name]}'),'#{node[:bcpc][:domain_name]}','#{node[:bcpc][:management][:vip]}','NS',300,NULL);
                    INSERT INTO records_static (domain_id, name, content, type, ttl, prio) VALUES ((SELECT id FROM domains WHERE name='#{node[:bcpc][:domain_name]}'),'#{node[:bcpc][:domain_name]}','#{node[:bcpc][:management][:vip]}','A',300,NULL);
            ]
            self.notifies :restart, "service[pdns]", :delayed
            self.resolve_notification_references
        end
    end
end

ruby_block "powerdns-table-view" do
    block do
        if not system "mysql -uroot -p#{get_config('mysql-root-password')} -e 'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = \"#{node['bcpc']['pdns_dbname']}\" AND TABLE_NAME=\"records\"'|grep \"records\"" then
            %x[ mysql -uroot -p#{get_config('mysql-root-password')} #{node['bcpc']['pdns_dbname']} <<-EOH
                    CREATE OR REPLACE VIEW records AS
                        SELECT id,domain_id,name,type,content,ttl,prio,change_date FROM records_static UNION
                        SELECT nova.instances.id+10000 AS id, (SELECT id FROM domains WHERE name='#{node[:bcpc][:domain_name]}') AS domain_id, CONCAT(nova.instances.hostname,'.#{node[:bcpc][:domain_name]}') AS name, 'A' AS type, nova.floating_ips.address AS content, 300 AS ttl, NULL AS type, NULL AS change_date
                           FROM nova.instances, nova.fixed_ips, nova.floating_ips
                           WHERE nova.instances.uuid = nova.fixed_ips.instance_uuid and nova.floating_ips.fixed_ip_id = nova.fixed_ips.id;
                    CREATE INDEX rec_name_index ON records(name);
                    CREATE INDEX nametype_index ON records(name,type);
                    CREATE INDEX domain_id ON records(domain_id);
            ]
            self.notifies :restart, "service[pdns]", :delayed
            self.resolve_notification_references
        end
    end
end

service "pdns" do
    action [ :enable, :start ]
end
