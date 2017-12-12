# HDFS
## namenode
template node['bcpc']['hadoop']['jmxtrans_agent']['namenode']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['namenode']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['namenode']['queries']
  )
end

# datanode
template node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['queries']
  )
end

# journalnode
template node['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['journalnode']['queries']
  )
end

# HBase
## master
template node['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['queries']
  )
end

# region server
template node['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['queries']
  )
end

# node manager
template node['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['queries']
  )
end

# resource manager
template node['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['resourcemanager']['queries']
  )
end

# zookeeper
template node['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['queries']
  )
end

# kafka
template node['bcpc']['hadoop']['jmxtrans_agent']['kafka']['xml'] do
  source 'jmxtrans_agent.xml.erb'
  mode 0o0644
  variables(
    collect_interval_in_seconds: node['bcpc']['hadoop']['jmxtrans_agent']['collect_interval_in_seconds'],
    output_writer_class: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['class'],
    output_writer_host: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['host'],
    output_writer_port: node['bcpc']['hadoop']['jmxtrans_agent']['output_writer']['port'],
    output_writer_name_prefix: node['bcpc']['hadoop']['jmxtrans_agent']['kafka']['name_prefix'],
    queries: node['bcpc']['hadoop']['jmxtrans_agent']['kafka']['queries']
  )
end
