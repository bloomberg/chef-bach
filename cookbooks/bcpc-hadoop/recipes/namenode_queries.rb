node.normal['bcpc']['hadoop']['graphite']['service_queries']['namenode'] = {
  'nnheapmem' => {
     'type' => "jmx",
     'query' => "memory.HeapMemoryUsage_committed",
     'trigger_val' => "max(61,0)",
     'value_type' => 3,
     'trigger_cond' => "=0",
     'trigger_name' => "NameNodeAvailability",
     'enable' => true,
     'trigger_dep' => [],
     'trigger_desc' => "Namenode service seems to be down",
     'severity' => 5,
     'route_to' => "admin"
  },
  'numstaledn' => {
     'type' => "jmx",
     'query' => "nn_fs_name_system_state.FSNamesystemState.NumStaleDataNodes",
     'enable' => true
  }
}
