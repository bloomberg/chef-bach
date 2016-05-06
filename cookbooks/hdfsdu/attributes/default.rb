##################################
#  hdfsdu specific attributes  #
##################################

default[:hdfsdu][:repo_url] = 'https://github.com/twitter/hdfs-du.git'
default[:hdfsdu][:repo_branch] = 'master'
default[:hdfsdu][:version] = '0.1.0'

default[:hdfsdu][:download_dir] = '/tmp'
default[:hdfsdu][:install_dir] = '/usr/lib'
default[:hdfsdu][:service_dir] = '/etc/init'
default[:hdfsdu][:log_dir] = '/var/log/hdfsdu'
default[:hdfsdu][:data_dir] = '/var/lib/hdfsdu/data'
default[:hdfsdu][:bin_dir] = "#{Dir.home}/chef-bcpc/bins"

default[:hdfsdu][:service_download_url] = 'http://localhost' 
default[:hdfsdu][:service_port] = 20000 
default[:hdfsdu][:service_endpoint] = "http://localhost:#{node[:hdfsdu][:service_port]}/index.html" 
default[:hdfsdu][:service_timeout] = 30 
default[:hdfsdu][:default_db_port] = 14001
default[:hdfsdu][:db_port] = 20001

default[:hdfsdu][:owner] = 'root'
default[:hdfsdu][:group] = 'root'
default[:hdfsdu][:user] = 'nobody'
default[:hdfsdu][:user_group] = 'nogroup'
default[:hdfsdu][:hdfs_user] = 'hdfsdu'
default[:hdfsdu][:hdfs_user_group] = 'nogroup'
default[:hdfsdu][:file_mode] = '0644'

default[:hdfsdu][:max_memory] = '256M'

default[:hdfsdu][:coordinator_job_name] = "hdfsdu_data_coord"
default[:hdfsdu][:workflow_job_name] = "hdfsdu_data_wf"
default[:hdfsdu][:hdfs_path] = "/user/#{node[:hdfsdu][:hdfs_user]}/hdfsdu"

# Ordered list of jars required to compile hdfsdu source
default[:hdfsdu][:dependent_jars] = [ '/usr/hdp/current/hadoop-client/hadoop-common.jar', 
                                      '/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core.jar', 
                                      '/usr/hdp/current/pig-client/pig-0.14.0.2.2.0.0-2041-core-h2.jar' ]
default[:hdfsdu][:jobtracker] = 'localhost:8032'
default[:hdfsdu][:namenode] = 'hdfs://test'
default[:hdfsdu][:mr_queue] = 'default'
default[:hdfsdu][:oozie_frequency] = 1440
default[:hdfsdu][:oozie_start_time] = '2015-04-09T00:00Z'
default[:hdfsdu][:oozie_end_time] = '2015-04-10T00:00Z'
default[:hdfsdu][:oozie_timezone] = 'UTC'
default[:hdfsdu][:oozie_url] = 'http://localhost:11000/oozie'

# Attribute stores the latest hdfsdu data timestamp that the server is serving
default[:hdfsdu][:image_timestamp] = "2015-04-09 00:00:00"
