# Set Kafka related zabbix triggers
trigger_chk_period = "#{node[:bcpc][:hadoop][:zabbix][:trigger_chk_period]}m"
node.set[:bcpc][:hadoop][:graphite][:service_queries][:kafka] = {
  'kafka_head.activeControllerCount' => {
     'type' => "jmx",
     'query' => "*.kafka.KafkaController.ActiveControllerCount.Value",
     'trigger_val' => "max(3m)",
     'trigger_cond' => "=0",
     'trigger_name' => "KafkaControllerCount",
     'enable' => true,
     'trigger_desc' => "Kafka broker seems to be down",
     'severity' => 4,
     'route_to' => "admin"
  },
  'kafka_head.OfflinePartitionsCount' => {
     'type' => "jmx",
     'query' => "*.kafka.KafkaController.OfflinePartitionsCount.Value",
     'trigger_val' => "min(3m)",
     'trigger_cond' => ">0",
     'trigger_name' => "KafkaOfflinePartitionsCount",
     'enable' => true,
     'trigger_desc' => "A Kafka partition seems to be offline",
     'severity' => 4,
     'route_to' => "admin"
  },
  'kafka_head.UnderReplicatedPartitions' => {
    'type' => "jmx",
     'query' => "*.kafka.ReplicaManager.UnderReplicatedPartitions.Value",
     'trigger_val' => "max(3m)",
     'trigger_cond' => ">0",
     'trigger_name' => "KafkaUnderReplicatedPartitions",
     'enable' => true,
     'trigger_desc' => "Kafka broker seems to have under replicated partitions",
     'severity' => 4,
     'route_to' => "admin"
  }
}
