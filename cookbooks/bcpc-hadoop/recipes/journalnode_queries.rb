triggers_sensitivity = '10m'
txid_threshold = node['bcpc']['hadoop']['journalnode']['alarm']['trigger_cond']['LastWrittenTxId']
epoch_threshold = node['bcpc']['hadoop']['journalnode']['alarm']['trigger_cond']['LastWriterEpoch']

node.default['bcpc']['hadoop']['graphite']['service_queries']['journalnode'] = {
  'journalnode.LastWrittenTxId' => {
    'query' => "rangeOfSeries(jmx.journalnode.#{node.chef_environment}.*.journal_node.Journal-#{node.chef_environment}.LastWrittenTxId)",
    'trigger_val' => "min(#{triggers_sensitivity})",
    'trigger_cond' => txid_threshold,
    'trigger_name' => 'JournalNodeLastWrittenTxId',
    'enable' => true,
    'trigger_desc' => "Journalnodes have LastWrittenTxId drifted apart more than #{txid_threshold}",
    'severity' => 3,
    'route_to' => 'admin'
  },
  'journalnode.LastWriterEpoch' => {
    'query' => "rangeOfSeries(jmx.journalnode.#{node.chef_environment}.*.journal_node.Journal-#{node.chef_environment}.LastWriterEpoch)",
    'trigger_val' => "min(#{triggers_sensitivity})",
    'trigger_cond' => epoch_threshold,
    'trigger_name' => 'JournalNodeLastWriterEpoch',
    'enable' => true,
    'trigger_desc' => "Journalnodes have LastWriterEpoch drifted apart more than #{epoch_threshold}",
    'severity' => 3,
    'route_to' => 'admin'
  }
}
