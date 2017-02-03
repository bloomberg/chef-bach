#
# Name of jmxtrans software downloaded
#
default['jmxtrans']['version'] = "256"
#
# Add additional JMX queries following the existing queries as sample
# Also refer to the jmxtrans community cookbook if queries of the category you are planning to add is
# already existing in the defualt attributes file
#
default['jmxtrans']['default_queries']['nodemanager'] = [
  {
    'obj' => "Hadoop:service=NodeManager,name=NodeManagerMetrics",
    'result_alias' => "NodeManager",
    'attr' => []
  }
]
default['jmxtrans']['default_queries']['resourcemanager'] = [
  { 
    'obj' => "Hadoop:service=ResourceManager,name=ClusterMetrics*",
    'result_alias' => "ResourceManager",
    'attr' => [ "NumActiveNMs" ]
  }, 
  {
    'type_name' => ["name", "q0", "user"],
    'obj' => "Hadoop:service=ResourceManager,name=QueueMetrics,q0=root,user=*",
    'result_alias' => "ResourceManager",
    'attr' => [ 
                "AppsRunning",                                  
                "AppsPending",                                  
                "AllocatedMB",                                  
                "AllocatedVCores",                              
                "AllocatedContainers",                          
                "PendingMB",                                    
                "PendingVCores",                                
                "PendingContainers",                            
                "ReservedMB",                                   
                "ReservedVCores",                               
                "ReservedContainers",                           
                "ActiveUsers",                                  
                "ActiveApplications"                            
    ]           
  }     
]
default['jmxtrans']['default_queries']['zookeeper'] = [
  {
     'obj' => "org.apache.ZooKeeperService:name0=ReplicatedServer_id*",
     'result_alias' => "zookeeper",
     'attr' => [ "QuorumSize" ]
  },
  {
    'obj' => "org.apache.ZooKeeperService:name0=ReplicatedServer_id*,name1=replica.*,name2=Follower,name3=InMemoryDataTree",
    'result_alias' => "zookeeper",
    'attr' => [ "NodeCount" ]
  }
]
default['jmxtrans']['default_queries']['kafka'] = [
  {
    'obj' => "\\\"kafka.server\\\":type=\\\"BrokerTopicMetrics\\\",name=*",
    'result_alias' => "kafka.BrokerTopicMetrics",
    'attr' => 
      [ 
        "Count", 
        "MeanRate", 
        "OneMinuteRate", 
        "FiveMinuteRate", 
        "FifteenMinuteRate" 
      ]
  },
  {
    'obj' => "\\\"kafka.server\\\":type=\\\"DelayedFetchRequestMetrics\\\",name=*",
    'result_alias' => "kafka.server.DelayedFetchRequestMetrics",
    'attr' => 
      [ 
        "Count", 
        "MeanRate", 
        "OneMinuteRate", 
        "FiveMinuteRate", 
        "FifteenMinuteRate"
      ]
  }
]
default['jmxtrans']['default_queries']['datanode'] = [
  {
    'obj' => "Hadoop:name=JvmMetrics,service=DataNode",
    'result_alias' => "dn_jvm_metrics",
    'attr' => 
      [
        "GcCount",
        "GcTimeMillis",
        "LogError",
        "LogFatal",
        "LogInfo",
        "LogWarn",
        "MemHeapCommittedM",
        "MemHeapUsedM",
        "MemMaxM",
        "MemNonHeapCommittedM",
        "MemNonHeapUsedM",
        "ThreadsBlocked",
        "ThreadsNew",
        "ThreadsRunnable",
        "ThreadsTerminated",
        "ThreadsTimedWaiting",
        "ThreadsWaiting"
      ]
  },
  {
    'obj' => "Hadoop:name=DataNodeInfo,service=DataNode",
    'result_alias' => "dn_data_node_info",
    'attr' => 
      [
        "ClusterId",
        "HttpPort",
        "NamenodeAddresses",
        "RpcPort",
        "Version",
        "VolumeInfo",
        "XceiverCount"
      ]
  }
]
default['jmxtrans']['default_queries']['namenode'] = [
  {
    'obj' => "Hadoop:name=JvmMetrics,service=NameNode",
    'result_alias' => "nn_jvm_metrics",
    'attr' => 
      [
        "GcCount",
        "GcCountCopy",
        "GcCountMarkSweepCompact",
        "GcTimeMillis",
        "GcTimeMillisCopy",
        "GcTimeMillisMarkSweepCompact",
        "LogError",
        "LogFatal",
        "LogInfo",
        "LogWarn",
        "MemHeapCommittedM",
        "MemHeapUsedM",
        "MemMaxM",
        "MemNonHeapCommittedM",
        "MemNonHeapUsedM",
        "ThreadsBlocked",
        "ThreadsNew",
        "ThreadsRunnable",
        "ThreadsTerminated",
        "ThreadsTimedWaiting",
        "ThreadsWaiting"
      ]
  },
  {
    'obj' => "Hadoop:name=FSNamesystem,service=NameNode",
    'result_alias' => "nn_fs_name_system",
    'attr' => 
      [
        "BlockCapacity",
        "BlocksTotal",
        "CapacityRemaining",
        "CapacityRemainingGB",
        "CapacityTotal",
        "CapacityTotalGB",
        "CapacityUsed",
        "CapacityUsedGB",
        "CapacityUsedNonDFS",
        "CorruptBlocks",
        "ExcessBlocks",
        "ExpiredHeartbeats",
        "FilesTotal",
        "LastCheckpointTime",
        "LastWrittenTransactionId",
        "MillisSinceLastLoadedEdits",
        "MissingBlocks",
        "PendingDataNodeMessageCount",
        "PendingDeletionBlocks",
        "PendingReplicationBlocks",
        "PostponedMisreplicatedBlocks",
        "ScheduledReplicationBlocks",
        "Snapshots",
        "SnapshottableDirectories",
        "StaleDataNodes",
        "TotalFiles",
        "TotalLoad",
        "TransactionsSinceLastCheckpoint",
        "TransactionsSinceLastLogRoll",
        "UnderReplicatedBlocks",
        "tag.HAState"
      ]
  },
  {
    'obj' => "Hadoop:name=FSNamesystemState,service=NameNode",
    'result_alias' => "nn_fs_name_system_state",
    'attr' => 
      [
        "BlocksTotal",
        "CapacityRemaining",
        "CapacityTotal",
        "CapacityUsed",
        "FSState",
        "FilesTotal",
        "NumDeadDataNodes",
        "NumLiveDataNodes",
        "NumStaleDataNodes",
        "PendingReplicationBlocks",
        "ScheduledReplicationBlocks",
        "TotalLoad",
        "UnderReplicatedBlocks"
      ]
  },
  {
    'obj' => "Hadoop:name=NameNodeActivity,service=NameNode",
    'result_alias' => "nn_name_node_activity",
    'attr' => 
      [
        "AddBlockOps",
        "AllowSnapshotOps",
        "BlockReportAvgTime",
        "BlockReportNumOps",
        "CreateFileOps",
        "CreateSnapshotOps",
        "CreateSymlinkOps",
        "DeleteFileOps",
        "DeleteSnapshotOps",
        "DisallowSnapshotOps",
        "FileInfoOps",
        "FilesAppended",
        "FilesCreated",
        "FilesDeleted",
        "FilesInGetListingOps",
        "FilesRenamed",
        "FsImageLoadTime",
        "GetAdditionalDatanodeOps",
        "GetBlockLocations",
        "GetLinkTargetOps",
        "GetListingOps",
        "ListSnapshottableDirOps",
        "RenameSnapshotOps",
        "SafeModeTime",
        "SnapshotDiffReportOps",
        "SyncsAvgTime",
        "SyncsNumOps",
        "TransactionsAvgTime",
        "TransactionsBatchedInSync",
        "TransactionsNumOps",
        "tag.Context",
        "tag.Hostname",
        "tag.ProcessName",
        "tag.SessionId"
      ]
  },
  {
    'obj' => "Hadoop:name=NameNodeInfo,service=NameNode",
    'result_alias' => "nn_name_node_info",
    'attr' => 
      [
        "BlockPoolId",
        "BlockPoolUsedSpace",
        "ClusterId",
        "DeadNodes",
        "DecomNodes",
        "DistinctVersionCount",
        "DistinctVersions",
        "Free",
        "JournalTransactionInfo",
        "LiveNodes",
        "NameDirStatuses",
        "NonDfsUsedSpace",
        "NumberOfMissingBlocks",
        "PercentBlockPoolUsed",
        "PercentRemaining",
        "PercentUsed",
        "SoftwareVersion",
        "Threads",
        "Total",
        "TotalBlocks",
        "TotalFiles",
        "UpgradeFinalized",
        "Used",
        "Version"
      ]
  }
]
default['jmxtrans']['default_queries']['hbase_master'] = [
  {
    'obj' => "Hadoop:name=JvmMetrics,service=HBase",
    'result_alias' => "hbm_jvm_metrics",
    'attr' => 
      [
        "GcCount",
        "GcTimeMillis",
        "LogError",
        "LogFatal",
        "LogInfo",
        "LogWarn",
        "MemHeapCommittedM",
        "MemHeapUsedM",
        "MemMaxM",
        "MemNonHeapCommittedM",
        "MemNonHeapUsedM",
        "ThreadsBlocked",
        "ThreadsNew",
        "ThreadsRunnable",
        "ThreadsTerminated",
        "ThreadsTimedWaiting",
        "ThreadsWaiting"
      ]
  },
  {
    'obj' => "Hadoop:name=Master,service=HBase,sub=Server",
    'result_alias' => "hbm_server",
    'attr' => 
      [
        "averageLoad",
        "clusterRequests",
        "masterActiveTime",
        "masterStartTime",
        "numDeadRegionServers",
        "numRegionServers"
      ]
  }
]
default['jmxtrans']['default_queries']['hbase_rs'] = [
  {
    'obj' => "Hadoop:name=JvmMetrics,service=HBase",
    'result_alias' => "hb_rs_jvm_metrics",
    'attr' => 
      [
        "GcCount",
        "GcTimeMillis",
        "LogError",
        "LogFatal",
        "LogInfo",
        "LogWarn",
        "MemHeapCommittedM",
        "MemHeapUsedM",
        "MemMaxM",
        "MemNonHeapCommittedM",
        "MemNonHeapUsedM",
        "ThreadsBlocked",
        "ThreadsNew",
        "ThreadsRunnable",
        "ThreadsTerminated",
        "ThreadsTimedWaiting",
        "ThreadsWaiting"
     ]
  },
  {   
    "obj"=> "Hadoop:name=IPC,service=HBase,sub=IPC",
    "result_alias"=> "hb_ipc",
    "attr" => 
    [
      "QueueCallTime_num_ops",
      "QueueCallTime_min",
      "QueueCallTime_max",
      "QueueCallTime_mean",
      "QueueCallTime_median",
      "QueueCallTime_75th_percentile",
      "QueueCallTime_95th_percentile",
      "QueueCallTime_99th_percentile",
      "authenticationFailures",
      "authorizationFailures",
      "authenticationSuccesses",
      "authorizationSuccesses",
      "ProcessCallTime_num_ops",
      "ProcessCallTime_min",
      "ProcessCallTime_max",
      "ProcessCallTime_mean",
      "ProcessCallTime_median",
      "ProcessCallTime_75th_percentile",
      "ProcessCallTime_95th_percentile",
      "ProcessCallTime_99th_percentile",
      "sentBytes",
      "receivedBytes",
      "queueSize",
      "numCallsInGeneralQueue",
      "numCallsInReplicationQueue",
      "numCallsInPriorityQueue",
      "numOpenConnections",
      "numActiveHandler"
    ]
  },
  {   
    "attr" => [],
    "obj" => "Hadoop:service=HBase,name=RegionServer,sub=Regions,*",
    "result_alias" => "hb_regions"
  },
  {   
    "attr" => [],
    "obj" => "Hadoop:service=HBase,name=RegionServer,sub=Replication,*",
    "result_alias" => "hb_replication"
  },
  {
    "obj" => "Hadoop:service=HBase,name=RegionServer,sub=Server,*",
    "result_alias" => "hb_rs_server",
    "attr" => []                        
  } 
]

# Override defaults for the jmxtrans cookbook
default['jmxtrans']['run_interval'] = "15"

# Set JMXTrans logging to INFO (the cookbook otherwise was defaulting to DEBUG)
default["jmxtrans"]["log_level"] = "INFO"
