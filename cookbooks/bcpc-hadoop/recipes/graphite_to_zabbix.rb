template "/usr/local/bin/run_zabbix_sender.sh" do
  source "zabbix.run_zabbix_sender.sh.erb"
  mode 0755
end

cookbook_file "/usr/local/bin/query_graphite.py" do
  source "query_graphite.py"
  mode 0744
  owner "root"
  group "root"
end

template "/usr/local/etc/query_graphite.config" do
  source "graphite.query_graphite.config.erb"
  mode 0544
end

ruby_block "zabbix_monitor" do
  block do
    require 'zabbixapi'
    #
    # Make connection to zabbix api url
    #
    zbx=ZabbixApi.connect(:url => "https://#{node['bcpc']['management']['vip']}:#{node['bcpc']['zabbix']['web_port']}/api_jsonrpc.php",:user => 'admin',:password => "#{get_config('zabbix-admin-password')}")
    if zbx.nil?
      Chef::Log.fatal!("Fatal error: could not connect to Zabbix server")
    end
    #
    # Looping through the graphite queries attribute to define the required zabbix hosts, items and triggers
    #
    graphite_hosts = (get_nodes_for("graphite","bcpc").map{|x| x.bcpc.management.ip}).join(",")
    cron_check_cond = Array.new
    node['bcpc']['hadoop']['graphite']['queries'].each do |host, value|
      value.each do |attr|    
        #
        # Create zabbix host group same as the chef environment name
        # 
        if zbx.hostgroups.get_id(:name => "#{node.chef_environment}").nil?
          zbx.hostgroups.create(:name => "#{node.chef_environment}")
        else
          Chef::Log.debug "Host group already defined; no action to be taken"
        end
        #
        # Create host entries in Zabbix. Note that these are dummy entries to define the required items and triggers
        #
        if zbx.hosts.get_id(:host => "#{host}").nil?
          zbx.hosts.create(:host => "#{host}",:interfaces => [ {:type => 1,:main => 1,:ip => '127.0.0.1', :dns => '127.0.0.1', :port => 10050, :useip => 0}],:groups => [ :groupid => zbx.hostgroups.get_id(:name => "#{node.chef_environment}") ])
        else
          Chef::Log.debug "Zabbix host #{host} is already defined; no action taken"
        end
        #
        # Define application which is used to group items 
        #
        if zbx.applications.get_id(:name => "hadoop").nil?
          Chef::Log.debug "Application hadoop not defined"
          zbx.applications.create(:name => "hadoop", :hostid => zbx.hosts.get_id(:host => "#{host}"))
        else
          Chef::Log.debug "Application hadoop already defined; no action to be taken"
        end
        #
        # Create zabbix items for each hosts which will accept data from zabbix sender processes
        # For details about the parameter values refer to Zabbix documentaton
        # https://www.zabbix.com/documentation/1.8/api/item
        #
        if zbx.items.get_id(:name => "#{attr['key']}",:host => "#{host}" ).nil?
          Chef::Log.debug "Item #{attr['key']} not defined"
	  if attr['history_days'].nil?
	    history_days = node['bcpc']['hadoop']['zabbix']['history_days']
	  else
	    history_days = attr['history_days']
	  end
	  if attr['trend_days'].nil?
	    trend_days = node['bcpc']['hadoop']['zabbix']['trend_days']
	  else
	    trend_days = attr['trend_days']
	  end
          zbx.items.create(:name => "#{attr['key']}", :description => "#{attr['key']}", :key_ => "#{attr['key']}", :type => 2, :value_type => 3, :data_type => 0, :history => history_days, :trends => trend_days,:hostid => zbx.hosts.get_id(:host => "#{host}"), :trapper_hosts => graphite_hosts)
        else
          Chef::Log.debug "Item #{attr['key']} already defined"
          zbx.items.create_or_update(:name => "#{attr['key']}", :description => "#{attr['key']}", :key_ => "#{attr['key']}", :type => 2, :value_type => 3, :data_type => 0, :history => history_days, :trends => trend_days,:hostid => zbx.hosts.get_id(:host => "#{host}"), :trapper_hosts => graphite_hosts)
        end
        #
        # Create zabbix triggers on the items so that actions can be taken if a trigger even occurs
        # For all triggers a companion trigger is created to check whether the zabbix sender cron job is active and sends data to zabbix
        #
        if attr['trigger_name'].nil?
          Chef::Log.debug "No triggers for this item"
	else
          if zbx.triggers.get_id(:description => "#{attr['trigger_name']}").nil?
            Chef::Log.debug "Trigger #{attr['trigger_name']} not defined"
            expr="{"+"#{host}"+":"+"#{attr['key']}"+"."+"#{attr['trigger_val']}"+"}"+"#{attr['trigger_cond']}"
            zbx.triggers.create(:description => "#{attr['trigger_name']}", :expression => expr, :comments => "Service down", :priority => 4, :status => 0)
            cron_check_cond << "{"+"#{host}"+":"+"#{attr['key']}"+".nodata(#{node["bcpc"]["hadoop"]["zabbix"]["cron_check_time"]})}=1"
          else
            Chef::Log.debug "Trigger #{attr['trigger_name']} already defined"
          end
        end
      end
    end
    #
    # Create a dummy trigger using all the items defined during the first run of this recipe to perform cron status check
    # Change reverted back due to issue https://www.zabbix.com/forum/showthread.php?t=46276
    #
    #if zbx.triggers.get_id(:description => "cron_check").nil?
    #  Chef::Log.debug "Trigger cron_check not defined"
    #  cron_check_expr = cron_check_cond.join("&")
    #  zbx.triggers.create(:description => "cron_check", :expression => cron_check_expr, :comments => "Cron down", :priority => 4, :status => 0)
    #else
    #  Chef::Log.debug "Trigger cron_check already defined"
    #end
  end
  action :create
end

cron "Run script to query graphite and send data to zabbix" do
  minute "*"
  hour   "*"
  user   "nobody"
  command  "/usr/local/bin/run_zabbix_sender.sh"
end
