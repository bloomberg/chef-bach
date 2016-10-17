include_recipe "bcpc-hadoop::zookeeper_impl"

mail_to_admin = "#{node[:bcpc][:hadoop][:zabbix][:mail_to_admin]}"

# Set Zookeeper related zabbix triggers
trigger_chk_period = "#{node["bcpc"]["hadoop"]["zabbix"]["trigger_chk_period"]}m"
node.set['bcpc']['hadoop']['graphite']['service_queries']['zookeeper'] = {
  'zookeeper.QuorumSize' => {
     'query' => "minSeries(jmx.zookeeper.*.zookeeper.QuorumSize)",
     'trigger_val' => "max(#{trigger_chk_period})",
     'trigger_cond' => "<#{node[:bcpc][:hadoop][:zookeeper][:servers].length}",
     'trigger_name' => "ZookeeperQuorumAvailability",
     'enable' => true,
     'trigger_desc' => "A zookeeper node seems to be down",
     'severity' => 5,
     'route_to' => "#{mail_to_admin}"
  }
}
