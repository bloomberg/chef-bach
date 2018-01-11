node.default['bcpc']['hadoop']['graphite']['service_queries']['namenode'] = {
  'namenode.HeapMemoryUsage_committed' => {
     'query' => "minSeries(jmx.namenode.#{node.chef_environment}.*.memory.HeapMemoryUsage_committed)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => "=0",
     'trigger_name' => "NameNodeAvailability",
     'enable' => true,
     'trigger_dep' => [],
     'trigger_desc' => "Namenode service seems to be down",
     'severity' => 5,
     'route_to' => "admin"
  },
  'namenode.NumDeadDataNodes' => {
     'query' => "maxSeries(jmx.namenode.#{node.chef_environment}.*.nn_fs_name_system_state.FSNamesystemState.NumDeadDataNodes)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => ">#{(node[:bcpc][:hadoop][:dn_hosts].length * 0.5).floor}",
     'trigger_name' => "NumDeadDataNodes",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "More than #{(node[:bcpc][:hadoop][:dn_hosts].length * 0.5).floor}(50%) datanodes are down",
     'severity' => 4,
     'route_to' => "admin"
  },
  'namenode.VolumeFailuresTotal' => {
     'query' => "maxSeries(jmx.namenode.#{node.chef_environment}.*.nn_fs_name_system_state.FSNamesystemState.VolumeFailuresTotal)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => ">2",
     'trigger_name' => "VolumeFailuresTotal",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "More than two volumes are failed",
     'severity' => 2,
     'route_to' => "admin"
  },
  'namenode.MissingBlocks' => {
     'query' => "maxSeries(jmx.namenode.#{node.chef_environment}.*.nn_fs_name_system.FSNamesystem.MissingBlocks)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => ">0",
     'trigger_name' => "MissingBlocks",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "Missing blocks reported",
     'severity' => 3,
     'route_to' => "admin"
  },
  'namenode.CorruptBlocks' => {
     'query' => "maxSeries(jmx.namenode.#{node.chef_environment}.*.nn_fs_name_system.FSNamesystem.CorruptBlocks)",
     'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m)",
     'trigger_cond' => ">0",
     'trigger_name' => "CorruptBlocks",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "Corrupted blocks reported",
     'severity' => 3,
     'route_to' => "admin"
  }
}
