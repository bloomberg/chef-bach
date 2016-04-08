# Set Kafka related zabbix triggers
trigger_chk_period = "#{node[:bcpc][:hadoop][:zabbix][:trigger_chk_period]}m"
node.set[:bcpc][:hadoop][:graphite][:service_queries][:kafka_head] = {
  'kafka_head.activeControllerCount' => {
     'query' => "jmx.kafka.*.kafka.KafkaController.ActiveControllerCount",
     'trigger_val' => "max(10m)",
     'trigger_cond' => "=0",
     'trigger_name' => "KafkaControllerCount",
     'enable' => true,
     'trigger_desc' => "Kafka broker seems to be down",
     'severity' => 4,
     'route_to' => "admin"
  },
  'kafka_head.OfflinePartitionsCount' => {
     'query' => "jmx.kafka.*.kafka.KafkaController.OfflinePartitionsCount",
     'trigger_val' => "min(10m)",
     'trigger_cond' => "=0",
     'trigger_name' => "KafkaOfflinePartitionsCount",
     'enable' => true,
     'trigger_desc' => "A Kafka partition seems to be offline",
     'severity' => 4,
     'route_to' => "admin"
  },
  'kafka_head.UnderReplicatedPartitions' => {
     'query' => "jmx.kafka.*.kafka.ReplicaManager.UnderReplicatedPartitions",
     'trigger_val' => "max(10m)",
     'trigger_cond' => ">0",
     'trigger_name' => "KafkaUnderReplicatedPartitions",
     'enable' => true,
     'trigger_desc' => "Kafka broker seems to have under replicated partitions",
     'severity' => 4,
     'route_to' => "admin"
  }
}
