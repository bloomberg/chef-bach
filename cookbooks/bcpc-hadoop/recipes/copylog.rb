#
# Recipe to copy log data from nodes into HDFS
# Flume is used to copy data and runs as an agent on the nodes
# 
#**** Attention ***** Attention ****
# This should be the last recipe in the runlist for any role since 
# individual recipes can make requests to copy log files to HDFS
# This can be achieved by adding the Copylog role as the last role to the node
# Since flume writes into HDFS nodes running this recipe should have HDFS
# client components installed on them.


dpkg_autostart "flume-agent" do
  allow false
end

%w{flume flume-agent}.each do |p|
  package p do
    action :upgrade
  end
end

service "flume-agent" do
  action [:stop, :disable]
end

bash "make_shared_logs_dir" do
  code <<EOH
  hdfs dfs -mkdir -p #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/ && \
  hdfs dfs -chown -R flume #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/
EOH
  user "hdfs"
  not_if "hdfs dfs -test #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/", :user => "hdfs"
end

template "/etc/flume/conf/flume-env.sh" do
  source "flume_flume-env.sh.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/etc/init.d/flume-agent-multi" do
  source "flume_flume-agent.erb"
  owner "root"
  group "root"
  mode "0755"
  action :create
end

if node['bcpc']['hadoop']['copylog_enable']
  service "flume-agent-multi" do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
    subscribes :restart, "template[/etc/flume/conf/flume-env.sh]", :delayed
  end
  node['bcpc']['hadoop']['copylog'].each do |id,f|
    if f['docopy'] 
      template "/etc/flume/conf/flume-#{id}.conf" do
        source "flume_flume-conf.erb"
        owner "root"
        group "root"
        mode "0444"
        action :create
        variables(:agent_name => "#{id}",
                  :log_location => "#{f['logfile']}" )
        notifies :restart,"service[flume-agent-multi-#{id}]",:delayed
      end
      
      service "flume-agent-multi-#{id}" do
        supports :status => true, :restart => true, :reload => false
        service_name "flume-agent-multi"
        action :start
        start_command "service flume-agent-multi start #{id}"
        restart_command "service flume-agent-multi restart #{id}"
        status_command "service flume-agent-multi status #{id}"
      end
    else
      service "flume-agent-multi-#{id}" do
        supports :status => true, :restart => true, :reload => false
        action :stop
        stop_command "service flume-agent-multi stop #{id}"
        status_command "service flume-agent-multi status #{id}"
      end

      file "/etc/flume/conf/flume-#{id}.conf" do
        action :delete
      end
    end
  end
else
  service "flume-agent-multi" do
    supports :status => true, :restart => true, :reload => false
    action [:stop, :disable]
  end
end
