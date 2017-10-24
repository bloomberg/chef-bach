# Set hbase related zabbix triggers
triggers_sensitivity = "#{node[:bcpc][:hadoop][:zabbix][:triggers_sensitivity]}m"

node.set[:bcpc][:hadoop][:graphite][:service_queries][:hbase_master] = {
  'hbase_master.HeapMemoryUsage_committed' => {
     'query' => "minSeries(jmx.hbase_master.*.memory.HeapMemoryUsage_committed)",
     'trigger_val' => "max(#{triggers_sensitivity})",
     'trigger_cond' => "=0",
     'trigger_name' => "HBaseMasterAvailability",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "HBase master seems to be down",
     'severity' => 4,
     'route_to' => "admin"
  },
  'hbase_master.numRegionServers' => {
     'query' => "maxSeries(jmx.hbase_master.*.hbm_server.Master.numRegionServers)",
     'trigger_val' => "max(#{triggers_sensitivity})",
     'trigger_cond' => "<#{node[:bcpc][:hadoop][:rs_hosts].length}",
     'trigger_name' => "HBaseRSAvailability",
     'enable' => true,
     'trigger_dep' => ["HBaseMasterAvailability"],
     'trigger_desc' => "HBase region server seems to be down",
     'severity' => 3,
     'route_to' => "admin"
  }
}
node.set[:bcpc][:hadoop][:graphite][:service_queries][:hbase_rs] = {
  'hbase_rs.GcTimeMillis' => {
     'query' => "maxSeries(jmx.hbase_rs.*.hb_rs_jvm_metrics.JvmMetrics.GcTimeMillis)",
     'trigger_val' => "max(#{triggers_sensitivity})",
     'trigger_cond' => ">60000",
     'trigger_name' => "HBaseRSGCTime",
     'enable' => true,
     'trigger_dep' => ["HBaseMasterAvailability"],
     'trigger_desc' => "HBase region server has GC longer than 60sec",
     'severity' => 2,
     'route_to' => "admin"
  }
}
