#
# Cookbook: bcpc-hadoop
# File: recipes/hbase_env.rb
#
# This recipe generates the hbase-env.sh shell script from Chef
# attributes.
#

#
# For some reason, node[:bcpc][:hadoop][:kerberos] doesn't exist when
# attr files are loaded, so we have to do this in a recipe.
#
if node[:bcpc][:hadoop][:kerberos][:enable]
    node.default[:bcpc][:hadoop][:hbase][:env]['HBASE_OPTS'] =
      node[:bcpc][:hadoop][:hbase][:env]['HBASE_OPTS'].to_s +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-client.jaas'

    node.default[:bcpc][:hadoop][:hbase][:env]['HBASE_MASTER_OPTS'] =
      node[:bcpc][:hadoop][:hbase][:env]['HBASE_MASTER_OPTS'].to_s +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-server.jaas'

    node.default[:bcpc][:hadoop][:hbase][:env]['HBASE_REGIONSERVER_OPTS'] =
      node[:bcpc][:hadoop][:hbase][:env]['HBASE_REGIONSERVER_OPTS'].to_s +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/regionserver.jaas'
end

#
# HBASE Master and RegionServer env.sh variables are updated with JMX
# related options when JMX is enabled
#
if node[:bcpc][:hadoop][:jmx_enabled]
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'].to_s +
    ' $HBASE_JMX_BASE ' +
    ' -Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:hbase_master][:jmx][:port].to_s

  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'].to_s +
    ' $HBASE_JMX_BASE ' +
    ' -Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:hbase_rs][:jmx][:port].to_s
end

template '/etc/hbase/conf/hbase-env.sh' do
  source 'generic_env.sh.erb'
  mode 0644
  variables(:options => node['bcpc']['hadoop']['hbase']['env'])
end

