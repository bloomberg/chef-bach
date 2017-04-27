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
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Link.send(:include, Bcpc_Hadoop::Helper)

node.default['bcpc']['hadoop']['copylog']['cheflog'] = {
    'logfile' => "#{node['chef_client']['log_dir']}/#{node['chef_client']['log_file']}",
    'docopy' => true
}

%w{flume flume-agent}.each do |p|
  package hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release]) do
    action :upgrade
  end
end

hdp_select('flume-server', node[:bcpc][:hadoop][:distribution][:active_release])

link "/etc/init.d/flume-agent-multi" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/flume/etc/init.d/flume-agent"
  notifies :run, "bash[kill flume-java]", :immediate
end

configure_kerberob  'flume_spnego' do
  service_name 'spnego'
end

flume_kerb' do
  service_name 'flume'
end

bash "kill flume-java" do
  code "pkill -u flume -f java"
  action :nothing
  returns [0, 1]
end

bash "make_shared_logs_dir" do
  code <<-EOH
  hdfs dfs -mkdir -p #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/ && \
  hdfs dfs -chown -R flume #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/
  EOH
  user "hdfs"
  not_if "hdfs dfs -test -d #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/", :user => "hdfs"
end

bash "set copylogs directory quota" do
  code <<-EOH
  hdfs dfsadmin -setSpaceQuota \
    #{node['bcpc']['hadoop']['copylog_quota']['space']} \
    #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/ && \
  hdfs dfsadmin -setQuota \
    #{node['bcpc']['hadoop']['copylog_quota']['files']} \
    #{node['bcpc']['hadoop']['hdfs_url']}/user/flume/logs/
  EOH
  user "hdfs"
end

template "/etc/init.d/flume-agent-multi" do
  source "flume_flume-agent.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/etc/flume/conf/flume-env.sh" do
  source "flume_flume-env.sh.erb"
  owner "root"
  group "root"
  mode "0755"
end

if node['bcpc']['hadoop']['copylog_enable']
  # hack for log file permissions
  # make restricted access syslog maintained logs publicly viewable if we are
  # running copylogs -- for flume and everyone
  %w{syslog authlog}.each do |log_type|
    if node['bcpc']['hadoop']['copylog'][log_type]['docopy']
      file "copylogs permission change #{node['bcpc']['hadoop']['copylog'][log_type]['logfile']}" do
        path node['bcpc']['hadoop']['copylog'][log_type]['logfile']
        mode '0644'
      end
    end
  end

  service "flume-agent-multi" do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
    subscribes :restart, "template[/etc/init.d/flume-agent-multi]", :delayed
    subscribes :restart, "template[/etc/flume/conf/flume-env.sh]", :delayed
    subscribes :restart, "template[/etc/flume/conf/log4j.properties]", :delayed
  end

  template '/etc/flume/conf/log4j.properties' do
    source "flume_log4j.properties.erb"
    mode '0644'
    owner 'flume'
    group 'flume'
    action :create
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
        subscribes :restart, "template[/etc/init.d/flume-agent-multi]", :delayed
        subscribes :restart, "template[/etc/flume/conf/log4j.properties]", :delayed
        subscribes :restart, "template[/etc/flume/conf/flume-env.sh]", :delayed
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
