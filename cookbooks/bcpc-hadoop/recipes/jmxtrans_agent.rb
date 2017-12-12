node['bcpc']['hadoop']['jmxtrans_agent'].tap do |agent|
  
  # HDFS
  ## namenode
  template agent['namenode']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['namenode']['name_prefix'],
      queries: agent['namenode']['queries']
    )
  end

  # datanode
  template agent['datanode']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['datanode']['name_prefix'],
      queries: agent['datanode']['queries']
    )
  end

  # journalnode
  template agent['journalnode']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['journalnode']['name_prefix'],
      queries: agent['journalnode']['queries']
    )
  end

  # HBase
  ## master
  template agent['hbase_master']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['hbase_master']['name_prefix'],
      queries: agent['hbase_master']['queries']
    )
  end

  # region server
  template agent['hbase_rs']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['hbase_rs']['name_prefix'],
      queries: agent['hbase_rs']['queries']
    )
  end

  # node manager
  template agent['nodemanager']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['nodemanager']['name_prefix'],
      queries: agent['nodemanager']['queries']
    )
  end

  # resource manager
  template agent['resourcemanager']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['resourcemanager']['name_prefix'],
      queries: agent['resourcemanager']['queries']
    )
  end

  # zookeeper
  template agent['zookeeper']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['zookeeper']['name_prefix'],
      queries: agent['zookeeper']['queries']
    )
  end

  # kafka
  template agent['kafka']['xml'] do
    source 'jmxtrans_agent.xml.erb'
    mode 0o644
    variables(
      collect_interval_in_seconds: agent['collect_interval_in_seconds'],
      output_writer_class: agent['output_writer']['class'],
      output_writer_host: agent['output_writer']['host'],
      output_writer_port: agent['output_writer']['port'],
      output_writer_name_prefix: agent['kafka']['name_prefix'],
      queries: agent['kafka']['queries']
    )
  end
end
