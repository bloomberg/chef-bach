#
# Cookbook Name: bcpc-hadoop
# Recipe Name: hive_config
# Description: To setup hive configuration only. No hive
# package will be installed through this Recipe
#

# Create hive password
hive_password = make_config('mysql-hive-password', secure_password)

# Hive table stats user
stats_user = make_config('mysql-hive-table-stats-user',
                         node['bcpc']['hadoop']['hive']['hive_table_stats_db_user'])
stats_password = make_config('mysql-hive-table-stats-password', secure_password)

%w(hive webhcat hcat hive-hcatalog).each do |w|
  directory "/etc/#{w}/conf.#{node.chef_environment}" do
    owner 'root'
    group 'root'
    mode 0o0755
    action :create
    recursive true
  end

  bash "update-#{w}-conf-alternatives" do
    code(%Q(
      update-alternatives --install /etc/#{w}/conf #{w}-conf /etc/#{w}/conf.#{node.chef_environment} 50
      update-alternatives --set #{w}-conf /etc/#{w}/conf.#{node.chef_environment}
    ))
  end
end

hive_site_vars = {
  is_hive_serverzzzz: node.run_list.expand(node.chef_environment).recipes.include?('bcpc-hadoop::hive_hcatalog'),
  mysql_hosts: node['bcpc']['hadoop']['mysql_hosts'].map { |m| m['hostname'] },
  zk_hosts: node['bcpc']['hadoop']['zookeeper']['servers'],
  hive_hosts: node['bcpc']['hadoop']['hive_hosts'],
  stats_user: stats_user,
  warehouse: "#{node['bcpc']['hadoop']['hdfs_url']}/user/hive/warehouse",
  metastore_keytab: "#{node['bcpc']['hadoop']['kerberos']['keytab']['dir']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['keytab']}",
  server_keytab: "#{node['bcpc']['hadoop']['kerberos']['keytab']['dir']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['keytab']}",
  kerberos_enabled: node['bcpc']['hadoop']['kerberos']['enable'],
  hs2_auth: node['bcpc']['hadoop']['hive']['server2']['authentication'],
  hs2_ldap_url: node['bcpc']['hadoop']['hive']['server2']['ldap_url'],
  hs2_ldap_domain: node['bcpc']['hadoop']['hive']['server2']['ldap_domain']
}

hive_site_vars['hive_sql_password'] = \
  if node.run_list.expand(node.chef_environment).recipes.include?('bcpc-hadoop::hive_hcatalog')
    hive_password
  else
    ''
  end

hive_site_vars['stats_sql_password'] = \
  if node.run_list.expand(node.chef_environment).recipes.include?('bcpc-hadoop::hive_hcatalog')
    stats_password
  else
    ''
  end

hive_site_vars['metastore_princ'] = \
  if node.run_list.expand(node.chef_environment).recipes.include?('bcpc-hadoop::hive_hcatalog')
    "#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost'] == '_HOST' ? float_host(node['fqdn']) : node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  else
    "#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost'] == '_HOST' ? '_HOST' : node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  end

hive_site_vars['server_princ'] = \
  if node.run_list.expand(node.chef_environment).recipes.include?('bcpc-hadoop::hive_hcatalog')
    "#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost'] == '_HOST' ? float_host(node['fqdn']) : node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  else
    "#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost'] == '_HOST' ? '_HOST' : node['bcpc']['hadoop']['kerberos']['data']['hive']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  end

generated_values =
  {
    'javax.jdo.option.ConnectionURL' =>
      'jdbc:mysql:loadbalance://' +
      hive_site_vars['mysql_hosts'].join(',') +
      ':3306/metastore?loadBalanceBlacklistTimeout=5000',

    'javax.jdo.option.ConnectionPassword' =>
      hive_site_vars['hive_sql_password'],

    'hive.metastore.uris' =>
      hive_site_vars['hive_hosts']
      .map { |s| 'thrift://' + float_host(s['hostname']) + ':9083' }
      .join(','),

    'hive.zookeeper.quorum' =>
      hive_site_vars['zk_hosts'].map { |s| float_host(s['hostname']) }.join(','),

    'hive.server2.support.dynamic.service.discovery' => 'true',

    'hive.server2.zookeeper.namespace' =>
      "HS2-#{node.chef_environment}-#{hive_site_vars[:hs2_auth]}",

    'hive.server2.thrift.bind.host' => float_host(node['fqdn']).to_s,

    'hive.server2.thrift.port' =>
      node['bcpc']['hadoop']['hive']['server2']['port'],

    'hive.metastore.warehouse.dir' =>
      hive_site_vars['warehouse'],

    'hive.stats.dbconnectionstring' =>
      'jdbc:mysql:loadbalance://' + hive_site_vars['mysql_hosts'].join(',') +
      ':3306/hive_table_stats?useUnicode=true' \
      '&characterEncoding=UTF-8' \
      '&user=' + hive_site_vars['stats_user'] +
      '&password=' + hive_site_vars['stats_sql_password']
  }

if hive_site_vars['kerberos_enabled'] && hive_site_vars['hs2_auth'] == 'KERBEROS'
  hs2_auth_values = {
    'hive.server2.authentication' =>
      hive_site_vars[:hs2_auth]
  }
elsif hive_site_vars[:hs2_auth] == 'LDAP'
  hs2_auth_values = {
    'hive.server2.authentication' =>
      hive_site_vars[:hs2_auth],

    'hive.server2.authentication.ldap.url' =>
      hive_site_vars[:hs2_ldap_url],

    'hive.server2.authentication.ldap.Domain' =>
      hive_site_vars[:hs2_ldap_domain]
  }
else
  hs2_auth_values = {}
end

generated_values.merge!(hs2_auth_values)

if hive_site_vars[:kerberos_enabled]
  kerberos_values =
    {
      'hive.metastore.sasl.enabled' => 'true',

      'hive.metastore.kerberos.keytab.file' =>
        hive_site_vars[:metastore_keytab],

      'hive.metastore.kerberos.principal' =>
        hive_site_vars[:metastore_princ],

      'hive.server2.authentication.kerberos.keytab' =>
        hive_site_vars[:server_keytab],

      'hive.server2.authentication.kerberos.principal' =>
        hive_site_vars[:server_princ]
    }
  generated_values.merge!(kerberos_values)
end

site_xml = node['bcpc']['hadoop']['hive']['site_xml']

# flatten_hash converts the tree of node object values to a hash with
# dot-notation keys.
# environment_values = flatten_hash(site_xml)

# The complete hash for hive_site.xml is a merger of values
# dynamically generated in this recipe, and hardcoded values from the
# environment and attribute files.
complete_hive_site_hash = generated_values.merge(site_xml)

template '/etc/hive/conf/hive-site.xml' do
  source 'generic_site.xml.erb'
  mode 0o0644
  variables(options: complete_hive_site_hash)
end

link "/etc/hive-hcatalog/conf.#{node.chef_environment}/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end

template '/etc/hive/conf/hive-env.sh' do
  source 'generic_env.sh.erb'
  mode 0o0644
  variables(options: node['bcpc']['hadoop']['hive']['env_sh'])
end

# This template contains no variables/substitutions.
template '/etc/hive/conf/hive-exec-log4j.properties' do
  source 'hv_hive-exec-log4j.properties.erb'
  mode 0o0644
end

# This template contains no variables/substitutions.
template '/etc/hive/conf/hive-log4j.properties' do
  source 'hv_hive-log4j.properties.erb'
  mode 0o0644
end
