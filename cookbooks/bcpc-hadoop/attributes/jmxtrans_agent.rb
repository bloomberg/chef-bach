default['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'] = 15
default['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'] = 'org.jmxtrans.agent.GraphitePlainTextTcpOutputWriter'
default['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'] = node['bcpc']['management']['vip']
default['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'] = node['bcpc']['graphite']['relay_port']

# default queries
default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] = [
  {
    'objectName' => 'java.lang:type=Memory',
    'resultAlias' => 'memory.#attribute#_#key#',
    'attributes' => 'HeapMemoryUsage,NonHeapMemoryUsage'
  },
  {
    'objectName' => 'java.lang:type=MemoryPool,name=*',
    'resultAlias' => 'memorypool.%name%.#attribute#_#key#',
    'attributes' => 'Usage'
  },
  {
    'objectName' => 'java.lang:type=GarbageCollector,name=*',
    'resultAlias' => 'gc.%name%.#attribute#',
    'attributes' => 'CollectionCount,CollectionTime'
  },
  {
    'objectName' => 'java.lang:type=Threading',
    'resultAlias' => 'threads.#attribute#',
    'attributes' => 'DaemonThreadCount,PeakThreadCount,ThreadCount,TotalStartedThreadCount'
  }
]

# HDFS namenode
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_namenode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['name_prefix'] = 'jmx.namenode'
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=NameNode',
    'resultAlias' => 'nn_jvm_metrics.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=FSNamesystem,service=NameNode',
    'resultAlias' => 'nn_fs_name_system.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=FSNamesystemState,service=NameNode',
    'resultAlias' => 'nn_fs_name_system_state.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=NameNodeActivity,service=NameNode',
    'resultAlias' => 'nn_name_node_activity.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=NameNodeInfo,service=NameNode',
    'resultAlias' => 'nn_name_node_info.%name%.#attribute#',
    'attributes' => ''
  }
]

# HDFS datanode
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_datanode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['name_prefix'] = 'jmx.datanode'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=DataNode',
    'resultAlias' => 'dn_jvm_metrics.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=DataNodeInfo,service=DataNode',
    'resultAlias' => 'dn_data_node_info.%name%.#attribute#',
    'attributes' => ''
  }
]

# HBase master
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_hbase_master.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['name_prefix'] = 'jmx.hbase_master'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
    'resultAlias' => 'hbm_jvm_metrics.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=Master,service=HBase,sub=Server',
    'resultAlias' => 'hbm_server.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=Master,service=HBase,sub=AssignmentManger',
    'resultAlias' => 'hbm_am.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:name=Master,service=HBase,sub=IPC',
    'resultAlias' => 'hbm_ipc.%name%.#attribute#',
    'attributes' => ''
  }
]

# HBase region server
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_hbase_rs.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['name_prefix'] = 'jmx.hbase_rs'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
    'resultAlias' => 'hb_rs_jvm_metrics.%name%.#attribute#',
    'attributes' =>
      'GcCount,' \
      'GcTimeMillis,' \
      'LogError,' \
      'LogFatal,' \
      'LogInfo,' \
      'LogWarn,' \
      'MemHeapCommittedM,' \
      'MemHeapUsedM,' \
      'MemMaxM,' \
      'MemNonHeapCommittedM,' \
      'MemNonHeapUsedM,' \
      'ThreadsBlocked,' \
      'ThreadsNew,' \
      'ThreadsRunnable,' \
      'ThreadsTerminated,' \
      'ThreadsTimedWaiting,' \
      'ThreadsWaiting'
  },
  {
    'objectName' => 'Hadoop:name=RegionServer,service=HBase,sub=IPC',
    'resultAlias' => 'hb_ipc.%name%.#attribute#',
    'attributes' =>
      'QueueCallTime_num_ops,' \
      'QueueCallTime_min,' \
      'QueueCallTime_max,' \
      'QueueCallTime_mean,' \
      'QueueCallTime_median,' \
      'QueueCallTime_75th_percentile,' \
      'QueueCallTime_95th_percentile,' \
      'QueueCallTime_99th_percentile,' \
      'authenticationFailures,' \
      'authorizationFailures,' \
      'authenticationSuccesses,' \
      'authorizationSuccesses,' \
      'ProcessCallTime_num_ops,' \
      'ProcessCallTime_min,' \
      'ProcessCallTime_max,' \
      'ProcessCallTime_mean,' \
      'ProcessCallTime_median,' \
      'ProcessCallTime_75th_percentile,' \
      'ProcessCallTime_95th_percentile,' \
      'ProcessCallTime_99th_percentile,' \
      'sentBytes,' \
      'receivedBytes,' \
      'queueSize,' \
      'numCallsInGeneralQueue,' \
      'numCallsInReplicationQueue,' \
      'numCallsInPriorityQueue,' \
      'numOpenConnections,' \
      'numActiveHandler'
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Regions,*',
    'resultAlias' => 'hb_regions.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Replication,*',
    'resultAlias' => 'hb_replication.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Server,*',
    'resultAlias' => 'hb_rs_server.%name%.#attribute#',
    'attributes' => ''
  }
]

# nodemanager
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_nodemanager.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['name_prefix'] = 'jmx.nodemanager'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:service=NodeManager,name=NodeManagerMetrics',
    'resultAlias' => 'NodeManager.%name%.#attribute#',
    'attributes' => ''
  }
]

# resource manager
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_resourcemanager.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['name_prefix'] = 'jmx.resourcemanager'
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:service=ResourceManager,name=ClusterMetrics*',
    'resultAlias' => 'ResourceManager.%name%.#attribute#',
    'attributes' => 'NumActiveNMs'
  },
  {
    'objectName' => 'Hadoop:service=ResourceManager,name=QueueMetrics,user=*',
    'resultAlias' => 'ResourceManager.%name%.#attribute#',
    'attributes' =>
      'AppsRunning,' \
      'AppsPending,' \
      'AllocatedMB,' \
      'AllocatedVCores,' \
      'AllocatedContainers,' \
      'PendingMB,' \
      'PendingVCores,' \
      'PendingContainers,' \
      'ReservedMB,' \
      'ReservedVCores,' \
      'ReservedContainers,' \
      'ActiveUsers,' \
      'ActiveApplications'
  }
]

# zookeeper
default['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_zookeeper.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['name_prefix'] = 'jmx.zookeeper'
default['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'org.apache.ZooKeeperService:name0=ReplicatedServer_id*',
    'resultAlias' => 'zookeeper.#attribute#',
    'attributes' => 'QuorumSize'
  },
  {
    'objectName' => 'org.apache.ZooKeeperService:name0=ReplicatedServer_id*,name1=replica.*,name2=Follower,name3=InMemoryDataTree',
    'resultAlias' => 'zookeeper.#attribute#',
    'attributes' => 'NodeCount'
  }
]

# kafka
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_kafka.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['name_prefix'] = 'jmx.kafka'
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => '\\\'kafka.server\\\':type=\\\'BrokerTopicMetrics\\\',name=*',
    'resultAlias' => 'kafka.BrokerTopicMetrics.%name%.#attribute#',
    'attributes' =>
      'Count,' \
      'MeanRate,' \
      'OneMinuteRate,' \
      'FiveMinuteRate,' \
      'FifteenMinuteRate'
  },
  {
    'objectName' => '\\\'kafka.server\\\':type=\\\'DelayedFetchRequestMetrics\\\',name=*',
    'resultAlias' => 'kafka.server.DelayedFetchRequestMetrics.%name%.#attribute#',
    'attributes' =>
      'Count,' \
      'MeanRate,' \
      'OneMinuteRate,' \
      'FiveMinuteRate,' \
      'FifteenMinuteRate'
  }
]
