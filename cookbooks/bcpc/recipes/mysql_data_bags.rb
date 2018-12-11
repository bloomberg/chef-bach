#
# Cookbook Name:: bcpc
# Recipe:: mysql_data_bags
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
# This recipe populates the data bags and vault secrets from which
# bcpc::mysql expects to withdraw its users and passwords.
#

{
  check: 'check',
  galera: 'sst',
  graphite: 'graphite',
  oozie: 'oozie',
  root: 'root',
  zabbix: 'zabbix',
  ambari: 'ambari'
}.each do |category, username|
  ruby_block "config mysql-#{category}-user" do
    block do
      make_config("mysql-#{category}-user", username)
    end
    not_if { get_config("mysql-#{category}-user") == "check" }
  end

  chef_vault_secret "mysql-#{category}" do
    data_bag 'os'
    raw_data lazy {
      { 'password' => secure_password }
    }
    admins Chef::Config.node_name
    search '*:*'
    action :create_if_missing
  end

  #
  # We call get_config! so that this recipe fails unless the new keys
  # are retrievable.
  #
  ruby_block 'validate configs' do
    block do
      if get_config!("mysql-#{category}-user").nil?
        raise "mysql-#{category}-user should not be nil!"
      end

      if get_config!('password', "mysql-#{category}", 'os').nil?
        raise "get_config(password, mysql-#{category}, os) should not be nil!"
      end
    end
  end
end
