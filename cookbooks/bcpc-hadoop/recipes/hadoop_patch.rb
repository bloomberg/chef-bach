directory '/usr/local/hadoop' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
remote_file '/usr/local/hadoop/hadoop-common-2.7.1.jar' do 
  #source 'http://10.0.100.3/hadoop-common-2.7.1.jar'
  source "#{get_binary_server_url}/hadoop-common-2.7.1.jar"
  checksum = 'sha256:9ed127f5a9a21c2f3efced7fd73e36d782b73b8eb9820c7ebef5169a94ded8f0'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end
# backup the previous file
remote_file '/usr/hdp/2.3.4.0-3485/hadoop/hadoop-common-2.7.1.2.3.4.0-3485.jar.bak' do
  #source 'http://10.0.100.3/hadoop-common-2.7.1.jar'
  source "file:///usr/hdp/2.3.4.0-3485/hadoop/hadoop-common-2.7.1.2.3.4.0-3485.jar"
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

file '/usr/hdp/2.3.4.0-3485/hadoop/hadoop-common-2.7.1.2.3.4.0-3485.jar' do
  owner 'root'
  group 'root'
  mode '0644'
  action :delete
end

link '/usr/hdp/current/hadoop-client/hadoop-common.jar' do
  action :delete
  only_if 'test -L /usr/hdp/current/hadoop-client/hadoop-common.jar'
end

#link '/usr/hdp/current/hadoop/hadoop-common.jar' do
#  action :delete
#  only_if 'test -L /usr/hdp/current/hadoop/hadoop-common.jar'
#end

link '/usr/hdp/current/hadoop-client/hadoop-common.jar' do
    to  '/usr/local/hadoop/hadoop-common-2.7.1.jar'
    only_if {File.exists?'/usr/local/hadoop/hadoop-common-2.7.1.jar'}                                                                                                      
    action :create
    notifies :restart, "service[hadoop-hdfs-namenode]"
end

#link '/usr/hdp/current/hadoop/hadoop-common.jar' do
#    to  '/usr/local/hadoop/hadoop-common-2.7.1.jar'
#    only_if {File.exists?'/usr/local/hadoop/hadoop-common-2.7.1.jar'}                                                                                                      
#    action :create
#    notifies :restart, "service[hadoop-hdfs-namenode]"
#end
