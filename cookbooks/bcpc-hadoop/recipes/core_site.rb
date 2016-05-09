core_site_values = node[:bcpc][:hadoop][:core][:site_xml]

mounts = node[:bcpc][:hadoop][:mounts]
core_site_generated_values =
{
 'mapreduce.cluster.local.dir' =>
   mounts.map{ |d| "file:///disk/#{d}/yarn/mapred-local" }.join(','),
 'yarn.nodemanager.log-dirs' =>
   mounts.map{ |d| "file:///disk/#{d}/yarn/logs" }.join(','),
}

if node[:bcpc][:hadoop][:kerberos][:enable]
  kerberos_properties =
    {
     'hadoop.security.authentication' => 'kerberos',
     'hadoop.security.authorization' => true,
     'hadoop.security.auth_to_local' =>
       node[:bcpc][:hadoop][:kerberos][:data].map { |ke,va|
       'RULE:[2:$1@$0](' +
         va['principal'] + '@.*' + node[:bcpc][:hadoop][:kerberos][:realm] +
         ')s/.*/' + va['owner'] + '/'
     }.join("\n"),
    }
  core_site_generated_values.merge!(kerberos_properties)
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

     'hadoop.security.group.mapping.ldap.bind.url' =>
       'ldap://' + node[:bcpc][:hadoop][:hdfs][:ldap][:domain] +
       ':' + node[:bcpc][:hadoop][:hdfs][:ldap][:port],

     'hadoop.security.group.mapping.ldap.base' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:domain].split('.')
       .map{ |s| "DC=#{s}" }.join(','),

     'hadoop.security.group.mapping.ldap.search.filter.user' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:search][:filter][:user],

     'hadoop.security.group.mapping.ldap.search.filter.group' =>
       node[:bcpc][:hadoop][:hdfs][:ldap][:search][:filter][:group],

     'hadoop.security.group.mapping.ldap.search.attr.member' =>
       'member',

     'hadoop.security.group.mapping.ldap.search.attr.group.name' =>
       'cn',
    }
  core_site_generated_values.merge!(ldap_properties)
end

complete_core_site_hash = core_site_generated_values.merge(core_site_values)

template "/etc/hadoop/conf/core-site.xml" do
  source "generic_site.xml.erb"
  mode 0644
  variables(:options => complete_core_site_hash)
end
