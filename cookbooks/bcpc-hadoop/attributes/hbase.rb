default['bcpc']['hadoop']['hbase']['root_dir'] = "#{node['bcpc']['hadoop']['hdfs_url']}/hbase"
default['bcpc']['hadoop']['hbase']['bulkload_staging_dir'] = "/tmp/hbase"
default["bcpc"]["hadoop"]["hbase"]["repl"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"] =  node.chef_environment.gsub("-","_")
default["bcpc"]["hadoop"]["hbase"]["repl"]["target"] = ""
default["bcpc"]["hadoop"]["hbase"]["superusers"] = ["hbase"]
# Interval in milli seconds when HBase major compaction need to be run. Disabled by default
default["bcpc"]["hadoop"]["hbase"]["major_compact"]["time"] = 0
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase_rs"]["xmn"]["size"] = 256
default["bcpc"]["hadoop"]["hbase_rs"]["xms"]["size"] = 1024
default["bcpc"]["hadoop"]["hbase_rs"]["xmx"]["size"] = 1024
default["bcpc"]["hadoop"]["hbase_rs"]["mx_dir_mem"]["size"] = 256
default["bcpc"]["hadoop"]["hbase_rs"]["hdfs_dir_mem"]["size"] = 128
default["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["upperlimit"] = 0.4
default["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["lowerlimit"] = 0.2
default["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["all"] = false
default["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["period"] = 30000
default["bcpc"]["hadoop"]["hbase"]["blockcache"]["size"] = 0.4
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["size"] = 1434
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["ioengine"] = "offheap"
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["combinedcache"]["percentage"] = 0.71
default["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"] = false
default["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["storefile"]["refresh"]["memstore"]["multiplier"] = 4
default["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["wait"]["for"]["primary"]["flush"] = true
default["bcpc"]["hadoop"]["hbase"]["hregion"]["memstore"]["block"]["multiplier"] = 8
default["bcpc"]["hadoop"]["hbase"]["ipc"]["client"]["specificthreadforwriting"] = true
default["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["get"] = 100000
default["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["multiget"] = 100000
default["bcpc"]["hadoop"]["hbase"]["meta"]["replica"]["count"] = 3
default["bcpc"]["hadoop"]["hbase"]["ipc"]["warn"]["responsetime"] = 250
default["bcpc"]["hadoop"]["hbase_master"]["hfilecleaner"]["ttl"] = 3600000
default["bcpc"]["hadoop"]["hbase_master"]["jmx"]["port"] = 10101
default["bcpc"]["hadoop"]["hbase_rs"]["jmx"]["port"] = 10102
#Apache Phoenix related attributes 
default["bcpc"]["hadoop"]["phoenix"]["tracing"]["enabled"] = false

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
  },
  {
    'obj' => "Hadoop:name=Master,service=HBase,sub=AssignmentManger",
    'result_alias' => "hbm_assignmgr",
    'attr' => 
      [
        "ritCount",
        "ritCountOverThreshold",
        "ritOldestAge"
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
    'obj' => "Hadoop:name=RegionServer,service=HBase,sub=Server",
    'result_alias' => "hb_rs_server",
    'attr' => [                        
      "regionCount",
      "storeCount",
      "hlogFileCount",
      "hlogFileSize",
      "storeFileCount",
      "memStoreSize",
      "storeFileSize",
      "regionServerStartTime",
      "storeFileIndexSize",
      "staticIndexSize",
      "staticBloomSize",
      "percentFilesLocal",
      "compactionQueueLength",
      "flushQueueLength",
      "totalRequestCount",
      "readRequestCount",
      "writeRequestCount",
      "slowGetCount",
      "slowAppendCount",
      "slowPutCount",
      "blockCacheFreeSize",
      "blockCacheHitCount",
      "blockCacheMissCount",
      "blockCacheCount",
      "blockCacheEvictionCount",
      "blockCacheSize",
      "blockCountHitPercent",
      "updatesBlockedTime",
      "Append_num_ops",
      "Append_min",
      "Append_max",
      "Append_mean",
      "Append_median",
      "Append_99th_percentile",
      "Append_95th_percentile",
      "Append_75th_percentile",
      "Delete_num_ops",
      "Delete_min",
      "Delete_max",
      "Delete_mean",
      "Delete_median",
      "Delete_99th_percentile",
      "Delete_95th_percentile",
      "Delete_75th_percentile",
      "Mutate_num_ops",
      "Mutate_min",
      "Mutate_max",
      "Mutate_mean",
      "Mutate_median",
      "Mutate_99th_percentile",
      "Mutate_95th_percentile",
      "Mutate_75th_percentile",
      "Get_num_ops",
      "Get_min",
      "Get_max",
      "Get_mean",
      "Get_median",
      "Get_99th_percentile",
      "Get_95th_percentile",
      "Get_75th_percentile",
      "Replay_num_ops",
      "Replay_min",
      "Replay_max",
      "Replay_mean",
      "Replay_median",
      "Replay_99th_percentile",
      "Replay_95th_percentile",
      "Replay_75th_percentile",
      "Increment_num_ops",
      "Increment_min",
      "Increment_max",
      "Increment_mean",
      "Increment_median",
      "Increment_99th_percentile",
      "Increment_95th_percentile",
      "Increment_75th_percentile"
    ]
  } 
]
