node['bcpc']['hadoop']['jmxtrans_agent'].tap do |agent|
  graphite = agent['graphite'].dup
  def graphite.with_prefix(component, cluster)
    self.merge('namePrefix' => "#{component['name_prefix']}.#{cluster}.#escaped_hostname#.")
  end

  statsd = agent['statsd'].dup
  def statsd.with_prefix(component)
    if component['name_prefix'] == 'jmx.hbase_regions'
      self.merge('metricName' => "bachHbaseRegion.#{component['name_prefix']}")
    else
      self.merge('metricName' => "bach.#{component['name_prefix']}")
    end
  end
  
  %w(namenode datanode journalnode hbase_master hbase_rs
     hbase_rs_regions nodemanager resourcemanager
     zookeeper kafka).each do |component|
    template agent[component]['xml'] do
      source 'jmxtrans_agent.xml.erb'
      mode 0o644
      variables(
        collect_interval_in_seconds: agent['collect_interval_in_seconds'],
        output_writers: agent['output_writers'],
        graphite: graphite.with_prefix(agent[component], node.chef_environment),
        statsd: statsd.with_prefix(agent[component]),
        queries: agent[component]['queries']
      )
    end
  end
end
