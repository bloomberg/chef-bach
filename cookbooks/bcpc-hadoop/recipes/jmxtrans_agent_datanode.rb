template node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml'] do
  source 'jmxtrans_agent_datanode.xml.erb'
  mode 0644
  variables ( lazy {
    {
      collectIntervalInSeconds: node['bcpc']['hadoop']['jmxtrans_agent']['collectIntervalInSeconds'],
      outputWriter_class:       node['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['class'],
      outputWriter_host:        node['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['host'],
      outputWriter_port:        node['bcpc']['hadoop']['jmxtrans_agent']['outputWriter']['port'],
      outputWriter_namePrefix:  node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['namePrefix'],
      queries:                  node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['queries']
    }
  })
end
