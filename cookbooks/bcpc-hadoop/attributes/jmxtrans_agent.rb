default['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'] = 15

 default['bcpc']['hadoop']['jmxtrans_agent']['output_writers'] = %w(graphite)

default['bcpc']['hadoop']['jmxtrans_agent']['graphite'].tap do |graphite|
  graphite['class'] = 'org.jmxtrans.agent.GraphitePlainTextTcpOutputWriter'
  graphite['host'] = node['bcpc']['management']['vip']
  graphite['port'] = node['bcpc']['graphite']['relay_port']
end

default['bcpc']['hadoop']['jmxtrans_agent']['statsd'].tap do |statsd|
  statsd['class'] = 'org.jmxtrans.agent.StatsDOutputWriter'
  statsd['host'] = node['bcpc']['management']['vip']
  statsd['port'] = 8125
end

# TODO OpenTSDB when it becomes available

jvm_metrics = 'GcCount,' \
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

hbase_ipc_metrics = 'ProcessCallTime_25th_percentile,' \
  'ProcessCallTime_75th_percentile,' \
  'ProcessCallTime_90th_percentile,' \
  'ProcessCallTime_95th_percentile,' \
  'ProcessCallTime_98th_percentile,' \
  'ProcessCallTime_99.9th_percentile,' \
  'ProcessCallTime_99th_percentile,' \
  'ProcessCallTime_max,' \
  'ProcessCallTime_mean,' \
  'ProcessCallTime_median,' \
  'ProcessCallTime_min,' \
  'ProcessCallTime_num_ops,' \
  'QueueCallTime_25th_percentile,' \
  'QueueCallTime_75th_percentile,' \
  'QueueCallTime_90th_percentile,' \
  'QueueCallTime_95th_percentile,' \
  'QueueCallTime_98th_percentile,' \
  'QueueCallTime_99.9th_percentile,' \
  'QueueCallTime_99th_percentile,' \
  'QueueCallTime_max,' \
  'QueueCallTime_mean,' \
  'QueueCallTime_median,' \
  'QueueCallTime_min,' \
  'QueueCallTime_num_ops,' \
  'RequestSize_25th_percentile,' \
  'RequestSize_75th_percentile,' \
  'RequestSize_90th_percentile,' \
  'RequestSize_95th_percentile,' \
  'RequestSize_98th_percentile,' \
  'RequestSize_99.9th_percentile,' \
  'RequestSize_99th_percentile,' \
  'RequestSize_max,' \
  'RequestSize_mean,' \
  'RequestSize_median,' \
  'RequestSize_min,' \
  'RequestSize_num_ops,' \
  'ResponseSize_25th_percentile,' \
  'ResponseSize_75th_percentile,' \
  'ResponseSize_90th_percentile,' \
  'ResponseSize_95th_percentile,' \
  'ResponseSize_98th_percentile,' \
  'ResponseSize_99.9th_percentile,' \
  'ResponseSize_99th_percentile,' \
  'ResponseSize_max,' \
  'ResponseSize_mean,' \
  'ResponseSize_median,' \
  'ResponseSize_min,' \
  'ResponseSize_num_ops,' \
  'TotalCallTime_25th_percentile,' \
  'TotalCallTime_75th_percentile,' \
  'TotalCallTime_90th_percentile,' \
  'TotalCallTime_95th_percentile,' \
  'TotalCallTime_98th_percentile,' \
  'TotalCallTime_99.9th_percentile,' \
  'TotalCallTime_99th_percentile,' \
  'TotalCallTime_max,' \
  'TotalCallTime_mean,' \
  'TotalCallTime_median,' \
  'TotalCallTime_min,' \
  'TotalCallTime_num_ops,' \
  'authenticationFailures,' \
  'authenticationSuccesses,' \
  'authorizationFailures,' \
  'authorizationSuccesses,' \
  'exceptions,' \
  'exceptions.FailedSanityCheckException,' \
  'exceptions.NotServingRegionException,' \
  'exceptions.OutOfOrderScannerNextException,' \
  'exceptions.RegionMovedException,' \
  'exceptions.RegionTooBusyException,' \
  'exceptions.ScannerResetException,' \
  'exceptions.UnknownScannerException,' \
  'numActiveHandler,' \
  'numCallsInGeneralQueue,' \
  'numCallsInPriorityQueue,' \
  'numCallsInReplicationQueue,' \
  'numGeneralCallsDropped,' \
  'numLifoModeSwitches,' \
  'numOpenConnections,' \
  'queueSize,' \
  'receivedBytes,' \
  'sentBytes'

hb_rs_server_metrics = 'Append_25th_percentile,' \
  'Append_75th_percentile,' \
  'Append_90th_percentile,' \
  'Append_95th_percentile,' \
  'Append_98th_percentile,' \
  'Append_99.9th_percentile,' \
  'Append_99th_percentile,' \
  'Append_max,' \
  'Append_mean,' \
  'Append_median,' \
  'Append_min,' \
  'Append_num_ops,' \
  'CompactionInputFileCount_25th_percentile,' \
  'CompactionInputFileCount_75th_percentile,' \
  'CompactionInputFileCount_90th_percentile,' \
  'CompactionInputFileCount_95th_percentile,' \
  'CompactionInputFileCount_98th_percentile,' \
  'CompactionInputFileCount_99.9th_percentile,' \
  'CompactionInputFileCount_99th_percentile,' \
  'CompactionInputFileCount_max,' \
  'CompactionInputFileCount_mean,' \
  'CompactionInputFileCount_median,' \
  'CompactionInputFileCount_min,' \
  'CompactionInputFileCount_num_ops,' \
  'CompactionInputSize_25th_percentile,' \
  'CompactionInputSize_75th_percentile,' \
  'CompactionInputSize_90th_percentile,' \
  'CompactionInputSize_95th_percentile,' \
  'CompactionInputSize_98th_percentile,' \
  'CompactionInputSize_99.9th_percentile,' \
  'CompactionInputSize_99th_percentile,' \
  'CompactionInputSize_max,' \
  'CompactionInputSize_mean,' \
  'CompactionInputSize_median,' \
  'CompactionInputSize_min,' \
  'CompactionInputSize_num_ops,' \
  'CompactionOutputFileCount_25th_percentile,' \
  'CompactionOutputFileCount_75th_percentile,' \
  'CompactionOutputFileCount_90th_percentile,' \
  'CompactionOutputFileCount_95th_percentile,' \
  'CompactionOutputFileCount_98th_percentile,' \
  'CompactionOutputFileCount_99.9th_percentile,' \
  'CompactionOutputFileCount_99th_percentile,' \
  'CompactionOutputFileCount_max,' \
  'CompactionOutputFileCount_mean,' \
  'CompactionOutputFileCount_median,' \
  'CompactionOutputFileCount_min,' \
  'CompactionOutputFileCount_num_ops,' \
  'CompactionOutputSize_25th_percentile,' \
  'CompactionOutputSize_75th_percentile,' \
  'CompactionOutputSize_90th_percentile,' \
  'CompactionOutputSize_95th_percentile,' \
  'CompactionOutputSize_98th_percentile,' \
  'CompactionOutputSize_99.9th_percentile,' \
  'CompactionOutputSize_99th_percentile,' \
  'CompactionOutputSize_max,' \
  'CompactionOutputSize_mean,' \
  'CompactionOutputSize_median,' \
  'CompactionOutputSize_min,' \
  'CompactionOutputSize_num_ops,' \
  'CompactionTime_25th_percentile,' \
  'CompactionTime_75th_percentile,' \
  'CompactionTime_90th_percentile,' \
  'CompactionTime_95th_percentile,' \
  'CompactionTime_98th_percentile,' \
  'CompactionTime_99.9th_percentile,' \
  'CompactionTime_99th_percentile,' \
  'CompactionTime_max,' \
  'CompactionTime_mean,' \
  'CompactionTime_median,' \
  'CompactionTime_min,' \
  'CompactionTime_num_ops,' \
  'Delete_25th_percentile,' \
  'Delete_75th_percentile,' \
  'Delete_90th_percentile,' \
  'Delete_95th_percentile,' \
  'Delete_98th_percentile,' \
  'Delete_99.9th_percentile,' \
  'Delete_99th_percentile,' \
  'Delete_max,' \
  'Delete_mean,' \
  'Delete_median,' \
  'Delete_min,' \
  'Delete_num_ops,' \
  'FlushMemstoreSize_25th_percentile,' \
  'FlushMemstoreSize_75th_percentile,' \
  'FlushMemstoreSize_90th_percentile,' \
  'FlushMemstoreSize_95th_percentile,' \
  'FlushMemstoreSize_98th_percentile,' \
  'FlushMemstoreSize_99.9th_percentile,' \
  'FlushMemstoreSize_99th_percentile,' \
  'FlushMemstoreSize_max,' \
  'FlushMemstoreSize_mean,' \
  'FlushMemstoreSize_median,' \
  'FlushMemstoreSize_min,' \
  'FlushMemstoreSize_num_ops,' \
  'FlushOutputSize_25th_percentile,' \
  'FlushOutputSize_75th_percentile,' \
  'FlushOutputSize_90th_percentile,' \
  'FlushOutputSize_95th_percentile,' \
  'FlushOutputSize_98th_percentile,' \
  'FlushOutputSize_99.9th_percentile,' \
  'FlushOutputSize_99th_percentile,' \
  'FlushOutputSize_max,' \
  'FlushOutputSize_mean,' \
  'FlushOutputSize_median,' \
  'FlushOutputSize_min,' \
  'FlushOutputSize_num_ops,' \
  'FlushTime_25th_percentile,' \
  'FlushTime_75th_percentile,' \
  'FlushTime_90th_percentile,' \
  'FlushTime_95th_percentile,' \
  'FlushTime_98th_percentile,' \
  'FlushTime_99.9th_percentile,' \
  'FlushTime_99th_percentile,' \
  'FlushTime_max,' \
  'FlushTime_mean,' \
  'FlushTime_median,' \
  'FlushTime_min,' \
  'FlushTime_num_ops,' \
  'Get_25th_percentile,' \
  'Get_75th_percentile,' \
  'Get_90th_percentile,' \
  'Get_95th_percentile,' \
  'Get_98th_percentile,' \
  'Get_99.9th_percentile,' \
  'Get_99th_percentile,' \
  'Get_max,' \
  'Get_mean,' \
  'Get_median,' \
  'Get_min,' \
  'Get_num_ops,' \
  'Increment_25th_percentile,' \
  'Increment_75th_percentile,' \
  'Increment_90th_percentile,' \
  'Increment_95th_percentile,' \
  'Increment_98th_percentile,' \
  'Increment_99.9th_percentile,' \
  'Increment_99th_percentile,' \
  'Increment_max,' \
  'Increment_mean,' \
  'Increment_median,' \
  'Increment_min,' \
  'Increment_num_ops,' \
  'MajorCompactionInputFileCount_25th_percentile,' \
  'MajorCompactionInputFileCount_75th_percentile,' \
  'MajorCompactionInputFileCount_90th_percentile,' \
  'MajorCompactionInputFileCount_95th_percentile,' \
  'MajorCompactionInputFileCount_98th_percentile,' \
  'MajorCompactionInputFileCount_99.9th_percentile,' \
  'MajorCompactionInputFileCount_99th_percentile,' \
  'MajorCompactionInputFileCount_max,' \
  'MajorCompactionInputFileCount_mean,' \
  'MajorCompactionInputFileCount_median,' \
  'MajorCompactionInputFileCount_min,' \
  'MajorCompactionInputFileCount_num_ops,' \
  'MajorCompactionInputSize_25th_percentile,' \
  'MajorCompactionInputSize_75th_percentile,' \
  'MajorCompactionInputSize_90th_percentile,' \
  'MajorCompactionInputSize_95th_percentile,' \
  'MajorCompactionInputSize_98th_percentile,' \
  'MajorCompactionInputSize_99.9th_percentile,' \
  'MajorCompactionInputSize_99th_percentile,' \
  'MajorCompactionInputSize_max,' \
  'MajorCompactionInputSize_mean,' \
  'MajorCompactionInputSize_median,' \
  'MajorCompactionInputSize_min,' \
  'MajorCompactionInputSize_num_ops,' \
  'MajorCompactionOutputFileCount_25th_percentile,' \
  'MajorCompactionOutputFileCount_75th_percentile,' \
  'MajorCompactionOutputFileCount_90th_percentile,' \
  'MajorCompactionOutputFileCount_95th_percentile,' \
  'MajorCompactionOutputFileCount_98th_percentile,' \
  'MajorCompactionOutputFileCount_99.9th_percentile,' \
  'MajorCompactionOutputFileCount_99th_percentile,' \
  'MajorCompactionOutputFileCount_max,' \
  'MajorCompactionOutputFileCount_mean,' \
  'MajorCompactionOutputFileCount_median,' \
  'MajorCompactionOutputFileCount_min,' \
  'MajorCompactionOutputFileCount_num_ops,' \
  'MajorCompactionOutputSize_25th_percentile,' \
  'MajorCompactionOutputSize_75th_percentile,' \
  'MajorCompactionOutputSize_90th_percentile,' \
  'MajorCompactionOutputSize_95th_percentile,' \
  'MajorCompactionOutputSize_98th_percentile,' \
  'MajorCompactionOutputSize_99.9th_percentile,' \
  'MajorCompactionOutputSize_99th_percentile,' \
  'MajorCompactionOutputSize_max,' \
  'MajorCompactionOutputSize_mean,' \
  'MajorCompactionOutputSize_median,' \
  'MajorCompactionOutputSize_min,' \
  'MajorCompactionOutputSize_num_ops,' \
  'MajorCompactionTime_25th_percentile,' \
  'MajorCompactionTime_75th_percentile,' \
  'MajorCompactionTime_90th_percentile,' \
  'MajorCompactionTime_95th_percentile,' \
  'MajorCompactionTime_98th_percentile,' \
  'MajorCompactionTime_99.9th_percentile,' \
  'MajorCompactionTime_99th_percentile,' \
  'MajorCompactionTime_max,' \
  'MajorCompactionTime_mean,' \
  'MajorCompactionTime_median,' \
  'MajorCompactionTime_min,' \
  'MajorCompactionTime_num_ops,' \
  'Mutate_25th_percentile,' \
  'Mutate_75th_percentile,' \
  'Mutate_90th_percentile,' \
  'Mutate_95th_percentile,' \
  'Mutate_98th_percentile,' \
  'Mutate_99.9th_percentile,' \
  'Mutate_99th_percentile,' \
  'Mutate_max,' \
  'Mutate_mean,' \
  'Mutate_median,' \
  'Mutate_min,' \
  'Mutate_num_ops,' \
  'PauseTimeWithGc_25th_percentile,' \
  'PauseTimeWithGc_75th_percentile,' \
  'PauseTimeWithGc_90th_percentile,' \
  'PauseTimeWithGc_95th_percentile,' \
  'PauseTimeWithGc_98th_percentile,' \
  'PauseTimeWithGc_99.9th_percentile,' \
  'PauseTimeWithGc_99th_percentile,' \
  'PauseTimeWithGc_max,' \
  'PauseTimeWithGc_mean,' \
  'PauseTimeWithGc_median,' \
  'PauseTimeWithGc_min,' \
  'PauseTimeWithGc_num_ops,' \
  'PauseTimeWithoutGc_25th_percentile,' \
  'PauseTimeWithoutGc_75th_percentile,' \
  'PauseTimeWithoutGc_90th_percentile,' \
  'PauseTimeWithoutGc_95th_percentile,' \
  'PauseTimeWithoutGc_98th_percentile,' \
  'PauseTimeWithoutGc_99.9th_percentile,' \
  'PauseTimeWithoutGc_99th_percentile,' \
  'PauseTimeWithoutGc_max,' \
  'PauseTimeWithoutGc_mean,' \
  'PauseTimeWithoutGc_median,' \
  'PauseTimeWithoutGc_min,' \
  'PauseTimeWithoutGc_num_ops,' \
  'Replay_25th_percentile,' \
  'Replay_75th_percentile,' \
  'Replay_90th_percentile,' \
  'Replay_95th_percentile,' \
  'Replay_98th_percentile,' \
  'Replay_99.9th_percentile,' \
  'Replay_99th_percentile,' \
  'Replay_max,' \
  'Replay_mean,' \
  'Replay_median,' \
  'Replay_min,' \
  'Replay_num_ops,' \
  'ScanSize_25th_percentile,' \
  'ScanSize_75th_percentile,' \
  'ScanSize_90th_percentile,' \
  'ScanSize_95th_percentile,' \
  'ScanSize_98th_percentile,' \
  'ScanSize_99.9th_percentile,' \
  'ScanSize_99th_percentile,' \
  'ScanSize_max,' \
  'ScanSize_mean,' \
  'ScanSize_median,' \
  'ScanSize_min,' \
  'ScanSize_num_ops,' \
  'ScanTime_25th_percentile,' \
  'ScanTime_75th_percentile,' \
  'ScanTime_90th_percentile,' \
  'ScanTime_95th_percentile,' \
  'ScanTime_98th_percentile,' \
  'ScanTime_99.9th_percentile,' \
  'ScanTime_99th_percentile,' \
  'ScanTime_max,' \
  'ScanTime_mean,' \
  'ScanTime_median,' \
  'ScanTime_min,' \
  'ScanTime_num_ops,' \
  'SplitTime_25th_percentile,' \
  'SplitTime_75th_percentile,' \
  'SplitTime_90th_percentile,' \
  'SplitTime_95th_percentile,' \
  'SplitTime_98th_percentile,' \
  'SplitTime_99.9th_percentile,' \
  'SplitTime_99th_percentile,' \
  'SplitTime_max,' \
  'SplitTime_mean,' \
  'SplitTime_median,' \
  'SplitTime_min,' \
  'SplitTime_num_ops,' \
  'averageRegionSize,' \
  'avgStoreFileAge,' \
  'blockCacheBloomChunkHitCount,' \
  'blockCacheBloomChunkMissCount,' \
  'blockCacheCount,' \
  'blockCacheCountHitPercent,' \
  'blockCacheDataHitCount,' \
  'blockCacheDataMissCount,' \
  'blockCacheDeleteFamilyBloomHitCount,' \
  'blockCacheDeleteFamilyBloomMissCount,' \
  'blockCacheEvictionCount,' \
  'blockCacheEvictionCountPrimary,' \
  'blockCacheExpressHitPercent,' \
  'blockCacheFileInfoHitCount,' \
  'blockCacheFileInfoMissCount,' \
  'blockCacheFreeSize,' \
  'blockCacheGeneralBloomMetaHitCount,' \
  'blockCacheGeneralBloomMetaMissCount,' \
  'blockCacheHitCount,' \
  'blockCacheHitCountPrimary,' \
  'blockCacheIntermediateIndexHitCount,' \
  'blockCacheIntermediateIndexMissCount,' \
  'blockCacheLeafIndexHitCount,' \
  'blockCacheLeafIndexMissCount,' \
  'blockCacheMetaHitCount,' \
  'blockCacheMetaMissCount,' \
  'blockCacheMissCount,' \
  'blockCacheMissCountPrimary,' \
  'blockCacheRootIndexHitCount,' \
  'blockCacheRootIndexMissCount,' \
  'blockCacheSize,' \
  'blockCacheTrailerHitCount,' \
  'blockCacheTrailerMissCount,' \
  'blockedRequestCount,' \
  'cellsCountCompactedFromMob,' \
  'cellsCountCompactedToMob,' \
  'cellsSizeCompactedFromMob,' \
  'cellsSizeCompactedToMob,' \
  'checkMutateFailedCount,' \
  'checkMutatePassedCount,' \
  'compactedCellsCount,' \
  'compactedCellsSize,' \
  'compactedInputBytes,' \
  'compactedOutputBytes,' \
  'compactionQueueLength,' \
  'compactionQueueLength,' \
  'flushQueueLength,' \
  'flushedCellsCount,' \
  'flushedCellsSize,' \
  'flushedMemstoreBytes,' \
  'flushedOutputBytes,' \
  'hlogFileCount,' \
  'hlogFileSize,' \
  'largeCompactionQueueLength,' \
  'majorCompactedCellsCount,' \
  'majorCompactedCellsSize,' \
  'majorCompactedInputBytes,' \
  'majorCompactedOutputBytes,' \
  'maxStoreFileAge,' \
  'memStoreSize,' \
  'minStoreFileAge,' \
  'mobFileCacheAccessCount,' \
  'mobFileCacheCount,' \
  'mobFileCacheEvictedCount,' \
  'mobFileCacheHitPercent,' \
  'mobFileCacheMissCount,' \
  'mobFlushCount,' \
  'mobFlushedCellsCount,' \
  'mobFlushedCellsSize,' \
  'mobScanCellsCount,' \
  'mobScanCellsSize,' \
  'mutationsWithoutWALCount,' \
  'mutationsWithoutWALSize,' \
  'numReferenceFiles,' \
  'pauseInfoThresholdExceeded,' \
  'pauseWarnThresholdExceeded,' \
  'percentFilesLocal,' \
  'percentFilesLocalSecondaryRegions,' \
  'readRequestCount,' \
  'regionCount,' \
  'regionServerStartTime,' \
  'rpcGetRequestCount,' \
  'rpcMultiRequestCount,' \
  'rpcMutateRequestCount,' \
  'rpcScanRequestCount,' \
  'slowAppendCount,' \
  'slowDeleteCount,' \
  'slowGetCount,' \
  'slowIncrementCount,' \
  'slowPutCount,' \
  'smallCompactionQueueLength,' \
  'splitQueueLength,' \
  'splitRequestCount,' \
  'splitSuccessCount,' \
  'staticBloomSize,' \
  'staticIndexSize,' \
  'storeCount,' \
  'storeFileCount,' \
  'storeFileIndexSize,' \
  'storeFileSize,' \
  'totalRequestCount,' \
  'updatesBlockedTime,' \
  'writeRequestCount'

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
    'attributes' => jvm_metrics
  },
  {
    'objectName' => 'Hadoop:name=FSNamesystem,service=NameNode',
    'resultAlias' => 'nn_fs_name_system.%name%.#attribute#',
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
      'LockQueueLength,' \
      'MillisSinceLastLoadedEdits,' \
      'MissingBlocks,' \
      'MissingReplOneBlocks,' \
      'NumActiveClients,' \
      'NumFilesUnderConstruction,' \
      'NumTimedOutPendingReplications,' \
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
      'TotalSyncCount,' \
      'TransactionsSinceLastCheckpoint,' \
      'TransactionsSinceLastLogRoll,' \
      'UnderReplicatedBlocks'
  },
  {
    'objectName' => 'Hadoop:name=FSNamesystemState,service=NameNode',
    'resultAlias' => 'nn_fs_name_system_state.%name%.#attribute#',
    'attributes' =>
      'BlockDeletionStartTime,' \
      'BlocksTotal,' \
      'CapacityRemaining,' \
      'CapacityTotal,' \
      'CapacityUsed,' \
      'EstimatedCapacityLostTotal,' \
      'FilesTotal,' \
      'FsLockQueueLength,' \
      'MaxObjects,' \
      'NumDeadDataNodes,' \
      'NumDecomDeadDataNodes,' \
      'NumDecomLiveDataNodes,' \
      'NumDecommissioningDataNodes,' \
      'NumLiveDataNodes,' \
      'NumStaleDataNodes,' \
      'NumStaleStorages,' \
      'PendingDeletionBlocks,' \
      'PendingReplicationBlocks,' \
      'ScheduledReplicationBlocks,' \
      'TotalLoad,' \
      'TotalSyncCount,' \
      'TotalSyncTimes,' \
      'UnderReplicatedBlocks,' \
      'VolumeFailuresTotal'
  },
  {
    'objectName' => 'Hadoop:name=NameNodeActivity,service=NameNode',
    'resultAlias' => 'nn_name_node_activity.%name%.#attribute#',
    'attributes' =>
      'AddBlockOps,' \
      'AllowSnapshotOps,' \
      'BlockOpsBatched,' \
      'BlockOpsQueued,' \
      'BlockReceivedAndDeletedOps,' \
      'BlockReportAvgTime,' \
      'BlockReportNumOps,' \
      'CacheReportAvgTime,' \
      'CacheReportNumOps,' \
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
      'FilesTruncated,' \
      'FsImageLoadTime,' \
      'GetAdditionalDatanodeOps,' \
      'GetBlockLocations,' \
      'GetEditAvgTime,' \
      'GetEditNumOps,' \
      'GetImageAvgTime,' \
      'GetImageNumOps,' \
      'GetLinkTargetOps,' \
      'GetListingOps,' \
      'ListSnapshottableDirOps,' \
      'PutImageAvgTime,' \
      'PutImageNumOps,' \
      'RenameSnapshotOps,' \
      'SafeModeTime,' \
      'SnapshotDiffReportOps,' \
      'StorageBlockReportOps,' \
      'SyncsAvgTime,' \
      'SyncsNumOps,' \
      'TotalFileOps,' \
      'TransactionsAvgTime,' \
      'TransactionsBatchedInSync,' \
      'TransactionsNumOps'
  },
  {
    'objectName' => 'Hadoop:name=NameNodeInfo,service=NameNode',
    'resultAlias' => 'nn_name_node_info.%name%.#attribute#',
    'attributes' =>
      'BlockPoolUsedSpace,' \
      'CacheCapacity,' \
      'CacheUsed,' \
      'DistinctVersionCount,' \
      'Free,' \
      'NonDfsUsedSpace,' \
      'NumberOfMissingBlocks,' \
      'NumberOfMissingBlocksWithReplicationFactorOne,' \
      'PercentBlockPoolUsed,' \
      'PercentRemaining,' \
      'PercentUsed,' \
      'Safemode,' \
      'Threads,' \
      'Total,' \
      'TotalBlocks,' \
      'TotalFiles,' \
      'Used'
  }
]

# HDFS datanode
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_datanode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['name_prefix'] = 'jmx.datanode'
default['bcpc']['hadoop']['jmxtrans_agent']['datanode']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=DataNode',
    'resultAlias' => 'dn_jvm_metrics.%name%.#attribute#',
    'attributes' => jvm_metrics
  },
  {
    'objectName' => 'Hadoop:name=DataNodeInfo,service=DataNode',
    'resultAlias' => 'dn_data_node_info.%name%.#attribute#',
    'attributes' => 'RpcPort,XceiverCount'
  }
]

# HDFS journalnode
default['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_journalnode.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['name_prefix'] = 'jmx.journalnode'
default['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:service=JournalNode,name=RpcDetailedActivityForPort*',
    'resultAlias' => 'journal_node.%name%.#attribute#',
    'attributes' =>
      'FinalizeLogSegmentAvgTime,' \
      'FinalizeLogSegmentNumOps,' \
      'GetEditLogManifestAvgTime,' \
      'GetEditLogManifestNumOps,' \
      'HeartbeatAvgTime,' \
      'HeartbeatNumOps,' \
      'JournalAvgTime,' \
      'JournalNumOps,' \
      'JournalOutOfSyncExceptionAvgTime,' \
      'JournalOutOfSyncExceptionNumOps,' \
      'StartLogSegmentAvgTime,' \
      'StartLogSegmentNumOps'
  },
  {
    'objectName' => 'Hadoop:service=JournalNode,name=RpcActivityForPort8485',
    'resultAlias' => 'journal_node.%name%.#attribute#',
    'attributes' =>
      'CallQueueLength,' \
      'NumOpenConnections,' \
      'ReceivedBytes,' \
      'RpcAuthenticationFailures,' \
      'RpcAuthenticationSuccesses,' \
      'RpcAuthorizationFailures,' \
      'RpcAuthorizationSuccesses,' \
      'RpcClientBackoff,' \
      'RpcProcessingTimeAvgTime,' \
      'RpcProcessingTimeNumOps,' \
      'RpcQueueTimeAvgTime,' \
      'RpcQueueTimeNumOps,' \
      'RpcSlowCalls,' \
      'SentBytes'
  },
  {
    'objectName' => 'Hadoop:service=JournalNode,name=UgiMetrics',
    'resultAlias' => 'journal_node.%name%.#attribute#',
    'attributes' =>
      'GetGroupsAvgTime,' \
      'GetGroupsNumOps,' \
      'LoginFailureAvgTime,' \
      'LoginFailureNumOps,' \
      'LoginSuccessAvgTime,' \
      'LoginSuccessNumOps,' \
      'RenewalFailures,' \
      'RenewalFailuresTotal'
  },
  {
    'objectName' => 'Hadoop:service=JournalNode,name=Journal-*',
    'resultAlias' => 'journal_node.%name%.#attribute#',
    'attributes' =>
      'BatchesWritten,' \
      'BatchesWrittenWhileLagging,' \
      'BytesWritten,' \
      'CurrentLagTxns,' \
      'LastPromisedEpoch,' \
      'LastWriterEpoch,' \
      'LastWrittenTxId,' \
      'Syncs300s50thPercentileLatencyMicros,' \
      'Syncs300s75thPercentileLatencyMicros,' \
      'Syncs300s90thPercentileLatencyMicros,' \
      'Syncs300s95thPercentileLatencyMicros,' \
      'Syncs300s99thPercentileLatencyMicros,' \
      'Syncs300sNumOps,' \
      'Syncs3600s50thPercentileLatencyMicros,' \
      'Syncs3600s75thPercentileLatencyMicros,' \
      'Syncs3600s90thPercentileLatencyMicros,' \
      'Syncs3600s95thPercentileLatencyMicros,' \
      'Syncs3600s99thPercentileLatencyMicros,' \
      'Syncs3600sNumOps,' \
      'Syncs60s50thPercentileLatencyMicros,' \
      'Syncs60s75thPercentileLatencyMicros,' \
      'Syncs60s90thPercentileLatencyMicros,' \
      'Syncs60s95thPercentileLatencyMicros,' \
      'Syncs60s99thPercentileLatencyMicros,' \
      'Syncs60sNumOps,' \
      'TxnsWritten'
  }
]

# HBase master
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_hbase_master.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['name_prefix'] = 'jmx.hbase_master'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
    'resultAlias' => 'hbm_jvm_metrics.%name%.#attribute#',
    'attributes' => jvm_metrics
  },
  {
    'objectName' => 'Hadoop:name=Master,service=HBase,sub=Server',
    'resultAlias' => 'hbm_server.%name%.#attribute#',
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
    'resultAlias' => 'hbm_am.%name%.#attribute#',
    'attributes' => 'ritCount,ritCountOverThreshold,ritOldestAge'
  },
  {
    'objectName' => 'Hadoop:name=Master,service=HBase,sub=IPC',
    'resultAlias' => 'hbm_ipc.%name%.#attribute#',
    'attributes' => hbase_ipc_metrics
  }
]

# HBase region server
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_hbase_rs.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['name_prefix'] = 'jmx.hbase_rs'
default['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:name=JvmMetrics,service=HBase',
    'resultAlias' => 'hb_rs_jvm_metrics.%name%.#attribute#',
    'attributes' => jvm_metrics
  },
  {
    'objectName' => 'Hadoop:name=RegionServer,service=HBase,sub=IPC',
    'resultAlias' => 'hb_ipc.%name%.#attribute#',
    'attributes' => hbase_ipc_metrics
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Regions,*',
    'resultAlias' => 'hb_regions.%name%.#attribute#',
    'attributes' => ''
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Replication,*',
    'resultAlias' => 'hb_replication.%name%.#attribute#',
    'attributes' =>
      'sink.ageOfLastAppliedOp,' \
      'sink.appliedBatches,' \
      'sink.appliedHFiles,' \
      'sink.appliedOps,' \
      'source.ageOfLastShippedOp,' \
      'source.closedLogsWithUnknownFileLength,' \
      'source.completedLogs,' \
      'source.completedRecoverQueues,' \
      'source.ignoredUncleanlyClosedLogContentsInBytes,' \
      'source.logEditsFiltered,' \
      'source.logEditsRead,' \
      'source.logReadInBytes,' \
      'source.region_replica_replication.ageOfLastShippedOp,' \
      'source.region_replica_replication.logEditsFiltered,' \
      'source.region_replica_replication.logEditsRead,' \
      'source.region_replica_replication.logReadInBytes,' \
      'source.region_replica_replication.shippedBatches,' \
      'source.region_replica_replication.shippedHFiles,' \
      'source.region_replica_replication.shippedKBs,' \
      'source.region_replica_replication.shippedOps,' \
      'source.region_replica_replication.sizeOfHFileRefsQueue,' \
      'source.region_replica_replication.sizeOfLogQueue,' \
      'source.region_replica_replicationclosedLogsWithUnknownFileLength,' \
      'source.region_replica_replicationcompletedLogs,' \
      'source.region_replica_replicationcompletedRecoverQueues,' \
      'source.region_replica_replicationignoredUncleanlyClosedLogContentsInBytes,' \
      'source.region_replica_replicationrepeatedLogFileBytes,' \
      'source.region_replica_replicationrestartedLogReading,' \
      'source.region_replica_replicationuncleanlyClosedLogs,' \
      'source.repeatedLogFileBytes,' \
      'source.restartedLogReading,' \
      'source.shippedBatches,' \
      'source.shippedHFiles,' \
      'source.shippedKBs,' \
      'source.shippedOps,' \
      'source.sizeOfHFileRefsQueue,' \
      'source.sizeOfLogQueue,' \
      'source.uncleanlyClosedLogs'
  },
  {
    'objectName' => 'Hadoop:service=HBase,name=RegionServer,sub=Server,*',
    'resultAlias' => 'hb_rs_server.%name%.#attribute#',
    'attributes' => hb_rs_server_metrics
  }
]

# nodemanager
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['xml'] = '/etc/hadoop/conf/jmxtrans_agent_nodemanager.xml'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['name_prefix'] = 'jmx.nodemanager'
default['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['queries'] = default['bcpc']['hadoop']['jmxtrans_agent']['basic']['queries'] + [
  {
    'objectName' => 'Hadoop:service=NodeManager,name=NodeManagerMetrics',
    'resultAlias' => 'NodeManager.%name%.#attribute#',
    'attributes' =>
      'AllocatedContainers,' \
      'AllocatedGB,' \
      'AllocatedVCores,' \
      'AvailableGB,' \
      'AvailableVCores,' \
      'BadLocalDirs,' \
      'BadLogDirs,' \
      'ContainerLaunchDurationAvgTime,' \
      'ContainerLaunchDurationNumOps,' \
      'ContainersCompleted,' \
      'ContainersFailed,' \
      'ContainersIniting,' \
      'ContainersKilled,' \
      'ContainersLaunched,' \
      'ContainersRunning,' \
      'GoodLocalDirsDiskUtilizationPerc,' \
      'GoodLogDirsDiskUtilizationPerc'
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
    'objectName' => 'Hadoop:service=ResourceManager,name=QueueMetrics,*',
    'resultAlias' => 'ResourceManager.%name%.%q0%_%q1%_%q2%.%user%.#attribute#',
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
