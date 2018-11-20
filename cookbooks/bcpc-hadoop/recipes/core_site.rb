core_site_values = node[:bcpc][:hadoop][:core][:site_xml]
node.run_state[:core_site_generated_values] = {}

if node[:bcpc][:hadoop][:kerberos][:enable]

  kerberos_data = node[:bcpc][:hadoop][:kerberos][:data]

  if kerberos_data[:spnego][:princhost] == '_HOST'
    spnego_host = '_HOST'
  else
    spnego_host = kerberos_data[:spnego][:princhost]
  end

  spnego_principal =
    kerberos_data[:spnego][:principal] + '/' + spnego_host + '@' +
    node[:bcpc][:hadoop][:kerberos][:realm]

  spnego_keytab = File.join(node[:bcpc][:hadoop][:kerberos][:keytab][:dir],
    kerberos_data[:namenode][:spnego_keytab])

  kerberos_properties =
    {
     'hadoop.http.authentication.type' => 'kerberos',
     'hadoop.http.authentication.simple.anonymous.allowed' => 'false',
     'hadoop.http.authentication.kerberos.principal' => spnego_principal,
     'hadoop.http.authentication.kerberos.keytab' => spnego_keytab,
     'hadoop.security.authentication' => 'kerberos',
     'hadoop.security.authorization' => true,
     'hadoop.security.auth_to_local' =>
       node[:bcpc][:hadoop][:kerberos][:data].reject { |ke, va|
         va['principal'] == 'HTTP' }.map { |ke,va|
       'RULE:[2:$1@$0](' +
         va['principal'] + '@.*' + node[:bcpc][:hadoop][:kerberos][:realm] +
         ')s/.*/' + va['owner'] + '/'
     }.join("\n") + "\n" +
     'DEFAULT',
    }
  node.run_state[:core_site_generated_values].merge!(kerberos_properties)
end

if node[:bcpc][:hadoop][:hdfs][:ldap][:integration]
  ldap_properties =
    {
     'hadoop.security.group.mapping' =>
       'org.apache.hadoop.security.LdapGroupsMapping',

     'hadoop.security.group.mapping.ldap.bind.password.file' =>
       '/etc/hadoop/conf/ldap-conn-pass.txt',

     'hadoop.security.group.mapping.ldap.bind.user' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:user],

     'hadoop.security.group.mapping.ldap.url' =>
       'ldap://' + node[:bcpc][:hadoop][:ldap][:domain] +
       ':' + node[:bcpc][:hadoop][:ldap][:port].to_s,

     'hadoop.security.group.mapping.ldap.base' =>
       node[:bcpc][:hadoop][:ldap][:domain].split('.')
       .map{ |s| "DC=#{s}" }.join(','),

     'hadoop.security.group.mapping.ldap.search.filter.user' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:search][:filter][:user],

     'hadoop.security.group.mapping.ldap.search.filter.group' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:search][:filter][:group],

     'hadoop.security.group.mapping.ldap.search.attr.member' =>
       'member',

     'hadoop.security.group.mapping.ldap.search.attr.group.name' =>
       'cn',

     'hadoop.security.group.mapping.ldap.search.group.hierarchy.levels' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:search][:depth],
    }
  node.run_state[:core_site_generated_values].merge!(ldap_properties)
end

subnet = node["bcpc"]["management"]["subnet"]
network_properties = {
  'hadoop.security.dns.interface' =>
      node["bcpc"]["networks"][subnet]["management"]["interface"]
}

node.run_state[:core_site_generated_values].merge!(network_properties)


ruby_block 'node.run_state[:core_site_generated_values]' do
  block do
    mounts = node.run_state['bcpc_hadoop_disks']['mounts']
    directory_values =
      {
       'mapreduce.cluster.local.dir' =>
         mounts.map{ |d| "file:///disk/#{d}/yarn/mapred-local" }.join(','),
       'yarn.nodemanager.log-dirs' =>
         mounts.map{ |d| "file:///disk/#{d}/yarn/logs" }.join(','),
      }
    node.run_state[:core_site_generated_values].merge!(directory_values)
    node.run_state[:core_site_generated_values].merge!(core_site_values)
  end
end

template '/etc/hadoop/conf/core-site.xml' do
  source 'generic_site.xml.erb'
  mode 0644
  variables lazy {{ options: node.run_state[:core_site_generated_values] }}
end
