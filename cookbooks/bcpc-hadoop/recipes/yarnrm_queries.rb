node.set['bcpc']['hadoop']['graphite']['service_queries']['resourcemanager'] = {
  'resourcemanager.HeapMemoryUsage_committed' => {
     'query' => "minSeries(jmx.resourcemanager.#{node.chef_environment}.*.memory.HeapMemoryUsage_committed)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => "=0",
     'trigger_name' => "YarnResourceManagerAvailability",
     'enable' => true,
     'trigger_dep' => [],
     'trigger_desc' => "Yarn ResourceManager seems to be down",
     'severity' => 4,
     'route_to' => "admin"
  },
  'resourcemanager.NumActiveNMs' => {
     'query' => "maxSeries(jmx.resourcemanager.#{node.chef_environment}.*.ResourceManager.ClusterMetrics.NumActiveNMs)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => "<#{(node[:bcpc][:hadoop][:dn_hosts].length * 0.5).ceil}",
     'trigger_name' => "NumActiveNMs",
     'enable' => true,
     'trigger_dep' => ["YarnResourceManagerAvailability"],
     'trigger_desc' => "More than 50% of Yarn node managers are down",
     'severity' => 4,
     'route_to' => "admin"
  }
}
