

directory "/disk" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

if node[:bcpc][:hadoop][:disks].length > 0 then
  node[:bcpc][:hadoop][:disks].each do |d|
    mount "/disk/#{d}" do
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64"
    end
  end
  node.set[:bcpc][:hadoop][:mounts] = node[:bcpc][:hadoop][:disks]
else
  (1..4).each do |i|
    directory "/disk/#{i}" do
      owner "root"
      group "root"
      mode 00755
      action :create
      recursive true
    end
  end
  node.set[:bcpc][:hadoop][:mounts] = ["1", "2", "3", "4"]
end


case node["platform_family"]
when "debian"
  apt_repository "cloudera" do
    uri node['bcpc']['repos']['cloudera']
    distribution node['lsb']['codename'] + '-cdh4'
    components ["contrib"]
    arch "amd64"
    key "cloudera-archive.key"
  end

  %w{hadoop hbase hive oozie pig zookeeper}.each do |w|
    directory "/etc/#{w}/conf.bcpc" do
      owner "root"
      group "root"
      mode 00755
      action :create
      recursive true
    end

    bash "update-#{w}-conf-alternatives" do
      code %Q{
       update-alternatives --install /etc/#{w}/conf #{w}-conf /etc/#{w}/conf.bcpc 50
       update-alternatives --set #{w}-conf /etc/#{w}/conf.bcpc
      }
    end
  end

when "rhel"
  ""
  # do things on RHEL platforms (redhat, centos, scientific, etc)
end

ruby_block "initialize-rabbitmq-config" do
    block do
      make_config('mysql-hive-password', secure_password)
    end
end


%w{capacity-scheduler.xml
   container-executor.cfg
   core-site.xml
   hadoop-metrics2.properties
   hadoop-metrics.properties
   hadoop-policy.xml
   hdfs-site.xml
   log4j.properties
   mapred-site.xml
   slaves
   ssl-client.xml
   ssl-server.xml
   yarn-site.xml
  }.each do |t|
   template "/etc/hadoop/conf/#{t}" do
     source "hdp_#{t}.erb"
     mode 0644
     variables(:nn_hosts => get_nodes_for("namenode") , 
               :zk_hosts => get_nodes_for("zookeeper_server"), 
               :jn_hosts => get_nodes_for("journalnode"),
               :rm_host  => get_nodes_for("resource_manager"),
               :dn_hosts => get_nodes_for("datanode"),
               :mounts => node[:bcpc][:hadoop][:mounts])
   end
end

%w{yarn-env.sh
  hadoop-env.sh}.each do |t|
 template "/etc/hadoop/conf/#{t}" do
   source "hdp_#{t}.erb"
   mode 0644
   variables(:nn_hosts => get_nodes_for("namenode"), 
             :zk_hosts => get_nodes_for("zookeeper_server"), 
             :jn_hosts => get_nodes_for("journalnode"),
             :mounts => node[:bcpc][:hadoop][:mounts])
 end
end

%w{zoo.cfg
  log4j.properties
  configuration.xsl
 }.each do |t|
 template "/etc/zookeeper/conf/#{t}" do
   source "zk_#{t}.erb"
   mode 0644
   variables(:nn_hosts => get_nodes_for("namenode"), 
             :zk_hosts => get_nodes_for("zookeeper_server"), 
             :jn_hosts => get_nodes_for("journalnode"),
             :mounts => node[:bcpc][:hadoop][:mounts])
 end
end

%w{hadoop-metrics.properties
   hbase-env.sh
   hbase-policy.xml
   hbase-site.xml
   log4j.properties
   regionservers}.each do |t|
   template "/etc/hbase/conf/#{t}" do
     source "hb_#{t}.erb"
     mode 0644
     variables(:nn_hosts => get_nodes_for("namenode"), 
               :zk_hosts => get_nodes_for("zookeeper_server"), 
               :jn_hosts => get_nodes_for("journalnode"),
               :rs_hosts => get_nodes_for("region_server"),
               :mounts => node[:bcpc][:hadoop][:mounts])
  end
end

%w{hive-exec-log4j.properties
   hive-log4j.properties 
   hive-site.xml }.each do |t| 
   template "/etc/hive/conf/#{t}" do
     source "hv_#{t}.erb"
     mode 0644
     variables(:mysql_hosts => get_mysql_nodes.map{ |m| m.hostname },
               :zk_hosts => get_nodes_for("zookeeper_server"), 
               :hive_host => get_nodes_for("hive_metastore"))
  end
end


package "openjdk-7-jdk" do
  action :upgrade
end

package "zookeeper" do
  action :upgrade
end

