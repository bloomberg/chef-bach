default['bcpc']['hadoop']['jmxtrans_agent']['collectIntervalInSeconds'] = 15
default['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['class'] = 'org.jmxtrans.agent.GraphitePlainTextTcpOutputWriter'
default['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['host'] = node['bcpc']['management']['vip']
default['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['port'] = node['bcpc']['graphite']['relay_port']

# default queries
default['bcpc']['hadoop']['jmxtrans_agent']['default']['queries'] = [
{
  'objectName' => 'java.lang:type=Memory',
    'resultAlias' => 'memory',
    'attributes' => 'HeapMemoryUsage,NonHeapMemoryUsage'
},
{
  'objectName' => 'java.lang:type=MemoryPool,name=*',
  'resualtAlias' => 'memorypool',
  'attributes' => 'Usage'
},
{
  'objectName' => 'java.lang:type=GarbageCollector,name=*',
  'resualtAlias' => 'gc',
  'attributes' => 'CollectionCount,CollectionTime'
},
{
  'objectName' => 'java.lang:type=Threading',
  'resualtAlias' => 'threads',
  'attributes' => 'DaemonThreadCount,PeakThreadCount,ThreadCount,TotalStartedThreadCount'
}
]


# HDFS namenode
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_namenode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['namePrefix'] = 'jmx.namenode'
default['bcpc']['hadoop']['jmxtrans_agent']['namenode']['queries'] = [
{
  'objectName' => 'Hadoop:name=JvmMetrics,service=NameNode',
  'resualtAlias' => 'nn_jvm_metrics',
  'attributes' =>
    'GcCount,' \
    'GcCountCopy,' \
    'GcCountMarkSweepCompact,' \
    'GcTimeMillis,' \
    'GcTimeMillisCopy,' \
    'GcTimeMillisMarkSweepCompact,' \
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
  'objectName' => 'Hadoop:name=FSNamesystem,service=NameNode',
  'resualtAlias' => 'nn_fs_name_system',
  'attributes' =>
    'BlockCapacity,' \
    'BlocksTotal,' \
    'CapacityRemaining,' \
    'CapacityRemainingGB,' \
    'CapacityTotal,' \
    'CapacityTotalGB,' \
    'CapacityUsed,' \
    'CapacityUsedGB,' \
    'CapacityUsedNonDFS,' \
    'CorruptBlocks,' \
    'ExcessBlocks,' \
    'ExpiredHeartbeats,' \
    'FilesTotal,' \
    'LastCheckpointTime,' \
    'LastWrittenTransactionId,' \
    'MillisSinceLastLoadedEdits,' \
    'MissingBlocks,' \
    'PendingDataNodeMessageCount,' \
    'PendingDeletionBlocks,' \
    'PendingReplicationBlocks,' \
    'PostponedMisreplicatedBlocks,' \
    'ScheduledReplicationBlocks,' \
    'Snapshots,' \
    'SnapshottableDirectories,' \
    'StaleDataNodes,' \
    'TotalFiles,' \
    'TotalLoad,' \
    'TransactionsSinceLastCheckpoint,' \
    'TransactionsSinceLastLogRoll,' \
    'UnderReplicatedBlocks,' \
    'tag.HAState'
},
{
  'objectName' => 'Hadoop:name=FSNamesystemState,service=NameNode',
  'resualtAlias' => 'nn_fs_name_system_state',
  'attributes' =>
    'BlocksTotal,' \
    'CapacityRemaining,' \
    'CapacityTotal,' \
    'CapacityUsed,' \
    'FSState,' \
    'FilesTotal,' \
    'NumDeadDataNodes,' \
    'NumLiveDataNodes,' \
    'NumStaleDataNodes,' \
    'PendingReplicationBlocks,' \
    'ScheduledReplicationBlocks,' \
    'TotalLoad,' \
    'UnderReplicatedBlocks'
},
{
  'objectName' => 'Hadoop:name=NameNodeActivity,service=NameNode',
  'resualtAlias' => 'nn_name_node_activity',
  'attributes' =>
    'AddBlockOps,' \
    'AllowSnapshotOps,' \
    'BlockReportAvgTime,' \
    'BlockReportNumOps,' \
    'CreateFileOps,' \
    'CreateSnapshotOps,' \
    'CreateSymlinkOps,' \
    'DeleteFileOps,' \
    'DeleteSnapshotOps,' \
    'DisallowSnapshotOps,' \
    'FileInfoOps,' \
    'FilesAppended,' \
    'FilesCreated,' \
    'FilesDeleted,' \
    'FilesInGetListingOps,' \
    'FilesRenamed,' \
    'FsImageLoadTime,' \
    'GetAdditionalDatanodeOps,' \
    'GetBlockLocations,' \
    'GetLinkTargetOps,' \
    'GetListingOps,' \
    'ListSnapshottableDirOps,' \
    'RenameSnapshotOps,' \
    'SafeModeTime,' \
    'SnapshotDiffReportOps,' \
    'SyncsAvgTime,' \
    'SyncsNumOps,' \
    'TransactionsAvgTime,' \
    'TransactionsBatchedInSync,' \
    'TransactionsNumOps,' \
    'tag.Context,' \
    'tag.Hostname,' \
    'tag.ProcessName,' \
    'tag.SessionId'
},
{
  'objectName' => 'Hadoop:name=NameNodeInfo,service=NameNode',
  'resualtAlias' => 'nn_name_node_info',
  'attributes' =>
    'BlockPoolId,' \
    'BlockPoolUsedSpace,' \
    'ClusterId,' \
    'DeadNodes,' \
    'DecomNodes,' \
    'DistinctVersionCount,' \
    'DistinctVersions,' \
    'Free,' \
    'JournalTransactionInfo,' \
    'LiveNodes,' \
    'NameDirStatuses,' \
    'NonDfsUsedSpace,' \
    'NumberOfMissingBlocks,' \
    'PercentBlockPoolUsed,' \
    'PercentRemaining,' \
    'PercentUsed,' \
    'SoftwareVersion,' \
    'Threads,' \
    'Total,' \
    'TotalBlocks,' \
    'TotalFiles,' \
    'UpgradeFinalized,' \
    'Used,' \
    'Version'
}
]

# HDFS datanode
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_datanode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['namePrefix'] = 'jmx.datanode'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['queries'] = [
{
  'objectName' => 'Hadoop:name=JvmMetrics,service=DataNode',
    'resultAlias' => 'dn_jvm_metrics',
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
  'objectName' => 'Hadoop:name=DataNodeInfo,service=DataNode',
  'resultAlias' => 'dn_data_node_info',
  'attributes' =>
    'ClusterId,' \
    'HttpPort,' \
    'NamenodeAddresses,' \
    'RpcPort,' \
    'Version,' \
    'VolumeInfo,' \
    'XceiverCount'
}
]


# HBase master
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['xml'] = '/etc/hbase/conf/jmxtrans_agent_hbase_master.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['namePrefix'] = 'jmx.hbase_master'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['queries'] = [
{
  'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
  'resualtAlias' => 'hbm_jvm_metrics',
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
  'objectName' => 'Hadoop:name=Master,service=HBase,sub=Server',
  'resualtAlias' => 'hbm_server',
  'attributes' =>
    'averageLoad,' \
    'clusterRequests,' \
    'masterActiveTime,' \
    'masterStartTime,' \
    'numDeadRegionServers,' \
    'numRegionServers'
},
{
  'objectName' => 'Hadoop:name=Master,service=HBase,sub=AssignmentManger',
  'resualtAlias' => 'hbm_am',
  'attributes' =>
    'ritOldestAge,' \
    'ritCountOverThreshold,' \
    'ritCount'
},
{
  'objectName' => 'Hadoop:name=Master,service=HBase,sub=IPC',
  'resualtAlias' => 'hbm_ipc',
  'attributes' => ''
}
]

# HBase region server
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_hbase_rs.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['namePrefix'] = 'jmx.hbase_rs'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['queries'] = [
{
  'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
  'resualtAlias' => 'hb_rs_jvm_metrics',
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
  'objectName'=> 'Hadoop:name=RegionServer,service=HBase,sub=IPC',
  'resualtAlias'=> 'hb_ipc',
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
  'resualtAlias' => 'hb_regions',
  'attributes' => ''
},
{
  'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Replication,*',
  'resualtAlias' => 'hb_replication',
  'attributes' => ''
},
{
  'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Server,*',
  'resualtAlias' => 'hb_rs_server',
  'attributes' => ''
}
]


# nodemanager
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_nodemanager.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['namePrefix'] = 'jmx.nodemanager'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['queries'] = [
{
  'objectName' => 'Hadoop:service=NodeManager,name=NodeManagerMetrics',
  'resualtAlias' => 'NodeManager',
  'attributes' => ''
}
]


# resource manager
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_resourcemanager.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['namePrefix'] = 'jmx.resourcemanager'
default['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['queries'] = [
{
  'objectName' => 'Hadoop:service=ResourceManager,name=ClusterMetrics*',
  'resualtAlias' => 'ResourceManager',
  'attributes' => 'NumActiveNMs'
},
{
  'objectName' => 'Hadoop:service=ResourceManager,name=QueueMetrics,user=*',
  'resualtAlias' => 'ResourceManager',
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
default['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['namePrefix'] = 'jmx.zookeeper'
default['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['queries'] = [
{
  'objectName' => 'org.apache.ZooKeeperService:name0=ReplicatedServer_id*',
  'resualtAlias' => 'zookeeper',
  'attributes' => 'QuorumSize'
},
{
  'objectName' => 'org.apache.ZooKeeperService:name0=ReplicatedServer_id*,name1=replica.*,name2=Follower,name3=InMemoryDataTree',
  'resualtAlias' => 'zookeeper',
  'attributes' => 'NodeCount'
}
]

# kafka
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_kafka.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['namePrefix'] = 'jmx.kafka'
default['bcpc']['hadoop']['jmxtrans_agent']['kafka']['queries'] = [
{
  'objectName' => '\\\'kafka.server\\\':type=\\\'BrokerTopicMetrics\\\',name=*',
  'resualtAlias' => 'kafka.BrokerTopicMetrics',
  'attributes' =>
    'Count,' \
    'MeanRate,' \
    'OneMinuteRate,' \
    'FiveMinuteRate,' \
    'FifteenMinuteRate'
},
{
  'objectName' => '\\\'kafka.server\\\':type=\\\'DelayedFetchRequestMetrics\\\',name=*',
  'resualtAlias' => 'kafka.server.DelayedFetchRequestMetrics',
  'attributes' =>
    'Count,' \
    'MeanRate,' \
    'OneMinuteRate,' \
    'FiveMinuteRate,' \
    'FifteenMinuteRate'
}
]
