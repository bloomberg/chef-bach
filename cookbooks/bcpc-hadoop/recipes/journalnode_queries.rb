triggers_sensitivity = '60m'

node.default['bcpc']['hadoop']['graphite']['service_queries']['journalnode'] = {
  'journalnode.LastWrittenTxId' => {
    'query' => "rangeOfSeries(jmx.journalnode.*.journal_node.Journal-#{node.chef_environment}.LastWrittenTxId)",
    'trigger_val' => "min(#{triggers_sensitivity})",
    'trigger_cond' => '>0',
    'trigger_name' => 'JournalNodeLastWrittenTxId',
    'enable' => true,
    'trigger_desc' => "Journal nodes have different LastWrittenTxId for #{triggers_sensitivity}",
    'severity' => 3,
    'route_to' => 'admin'
  },
  'journalnode.LastPromisedEpoch' => {
    'query' => "rangeOfSeries(jmx.journalnode.*.journal_node.Journal-#{node.chef_environment}.LastPromisedEpoch)",
    'trigger_val' => "min(#{triggers_sensitivity})",
    'trigger_cond' => '>0',
    'trigger_name' => 'JournalNodeLastPromisedEpoch',
    'enable' => true,
    'trigger_desc' => "Journal nodes have different LastPromisedEpoch for #{triggers_sensitivity}",
    'severity' => 3,
    'route_to' => 'admin'
  }
}
