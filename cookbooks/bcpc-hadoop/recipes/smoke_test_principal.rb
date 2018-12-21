# vim: tabstop=2:shiftwidth=2:softtabstop=2 
#
# Cookbook Name:: bcpc-hadoop
# Recipe:: smoke_test_principal
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

require 'base64'
require 'tempfile'

test_user = node['hadoop_smoke_tests']['oozie_user']
test_user_keytab = get_config('keytab', 'test_user_keytab', 'os')
results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results
bootstrap = get_bootstrap

admin_principal = node['krb5']['admin_principal']
admin_password = get_config 'krb5-admin-password'

execute "create #{test_user} principal" do
  command "kadmin -p #{admin_principal} -w #{admin_password} -q 'add_principal -randkey #{test_user}'" 
  sensitive true
  notifies :run, 'ruby_block[create temp file keytab]', :immediate
  only_if { node['bach']['krb5']['generate_keytabs'] && test_user_keytab == nil }
end

ruby_block "create temp file keytab"  do
  block do
    tmpfile = Tempfile.new(test_user)
    node.run_state["test_user_keytab_file"] = tmpfile.path
    tmpfile.close
    tmpfile.unlink
  end
  action :nothing
  notifies :run, "execute[dump keytab for #{test_user}]", :immediate
end

execute "dump keytab for #{test_user}" do
  command lazy {
    "kadmin -p #{admin_principal} -w #{admin_password} " \
    "-q \"ktadd -k #{node.run_state['test_user_keytab_file']} -norandkey #{test_user}\""
  }
  sensitive true
  action :nothing
  notifies :run, 'ruby_block[read in keytab]', :immediate
end

ruby_block 'read in keytab' do
  block do
    node.run_state['test_user_base64_keytab'] = 
      Base64.encode64(File.open(
        node.run_state["test_user_keytab_file"],'rb').read)
  end
  action :nothing
  notifies :create, 'chef_vault_secret[test_user_keytab]', :immediate
end

chef_vault_secret 'test_user_keytab' do
  provider ChefVaultCookbook::Provider::ChefVaultSecret
  data_bag 'os'
  raw_data ( lazy {{ 'keytab' => node.run_state['test_user_base64_keytab']}})
  search '*:*'
  admins Chef::Config.node_name
  action :nothing
  notifies :run, 'ruby_block[delete temp file keytab]', :immediate
end

ruby_block "delete temp file keytab" do
  block do
    File.unlink(node.run_state["test_user_keytab_file"])
  end
  action :nothing
end
