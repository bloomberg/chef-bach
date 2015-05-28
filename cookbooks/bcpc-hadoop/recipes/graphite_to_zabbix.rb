template node['bcpc']['zabbix']['scripts']['sender'] do
  source "zabbix.run_zabbix_sender.sh.erb"
  mode 0755
end

directory ::File.dirname(node['bcpc']['zabbix']['scripts']['mail']) do
  recursive true
  owner 'root' 
end

template node['bcpc']['zabbix']['scripts']['mail'] do
  source node["bcpc"]["hadoop"]["zabbix"]["mail_source"]
  cookbook node["bcpc"]["hadoop"]["zabbix"]["cookbook"] if node["bcpc"]["hadoop"]["zabbix"]["cookbook"]
  mode 0755
end

cookbook_file node['bcpc']['zabbix']['scripts']['query_graphite'] do
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
    zbx=ZabbixApi.connect(:url => "https://#{node['bcpc']['management']['vip']}:#{node['bcpc']['zabbix']['web_port']}/api_jsonrpc.php", 
                          :user => 'admin', 
                          :password => "#{get_config('zabbix-admin-password')}")
    if zbx.nil?
      Chef::Log.fatal!("Fatal error: could not connect to Zabbix server")
    end
    #
    # Looping through the graphite queries attribute to define the required zabbix hosts, items and triggers
    #
    graphite_hosts = (get_node_attributes(MGMT_IP_ATTR_SRCH_KEYS,"graphite","bcpc").map {|v| v['mgmt_ip']}).join(",")
    cron_check_cond = Array.new
    node['bcpc']['hadoop']['graphite']['queries'].each do |trigger_host, trigger|
      trigger.each do |trigger_attr|    
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
        if zbx.hosts.get_id(:host => "#{trigger_host}").nil?
          zbx.hosts.create(:host => "#{trigger_host}", 
                           :interfaces => [ {:type => 1,:main => 1,:ip => '127.0.0.1', :dns => '127.0.0.1', :port => 10050, :useip => 0}], 
                           :groups => [ :groupid => zbx.hostgroups.get_id(:name => "#{node.chef_environment}") ])
        else
          Chef::Log.debug "Zabbix host #{trigger_host} is already defined; no action taken"
        end
        #
        # Define application which is used to group items 
        #
        if zbx.applications.get_id(:name => "hadoop").nil?
          Chef::Log.debug "Application hadoop not defined"
          zbx.applications.create(:name => "hadoop", 
                                  :hostid => zbx.hosts.get_id(:host => "#{trigger_host}"))
        else
          Chef::Log.debug "Application hadoop already defined; no action to be taken"
        end
        #
        # Create zabbix items for each hosts which will accept data from zabbix sender processes
        # For details about the parameter values refer to Zabbix documentaton
        # https://www.zabbix.com/documentation/2.2/manual/api/reference/item
        #
        if zbx.items.get_id(:name => "#{trigger_attr['key']}",:host => "#{trigger_host}" ).nil?
          Chef::Log.debug "Item #{trigger_attr['key']} not defined"
	  if trigger_attr['history_days'].nil?
	    history_days = node['bcpc']['hadoop']['zabbix']['history_days']
	  else
	    history_days = trigger_attr['history_days']
	  end
	  if trigger_attr['trend_days'].nil?
	    trend_days = node['bcpc']['hadoop']['zabbix']['trend_days']
	  else
	    trend_days = trigger_attr['trend_days']
	  end
          zbx.items.create(:name => "#{trigger_attr['key']}", 
                           :description => "#{trigger_attr['key']}", 
                           :key_ => "#{trigger_attr['key']}", 
                           :type => 2, 
                           :value_type => 3, 
                           :data_type => 0, 
                           :history => history_days, 
                           :trends => trend_days, 
                           :hostid => zbx.hosts.get_id(:host => "#{trigger_host}"), 
                           :trapper_hosts => graphite_hosts)
        else
          Chef::Log.debug "Item #{trigger_attr['key']} already defined"
          zbx.items.create_or_update(:name => "#{trigger_attr['key']}", 
                                     :description => "#{trigger_attr['key']}", 
                                     :key_ => "#{trigger_attr['key']}", 
                                     :type => 2, 
                                     :value_type => 3, 
                                     :data_type => 0, 
                                     :history => history_days, 
                                     :trends => trend_days, 
                                     :hostid => zbx.hosts.get_id(:host => "#{trigger_host}"), 
                                     :trapper_hosts => graphite_hosts)
        end
        #
        # Create zabbix triggers on the items so that actions can be taken if a trigger even occurs
        # For all triggers a companion trigger is created to check whether the zabbix sender cron job is active and sends data to zabbix
        #
        if trigger_attr['trigger_name'].nil?
          Chef::Log.debug "No triggers for this item"
	else
          if trigger_attr.attribute?(:trigger_dep)
            dependencies = Array.new
            trigger_attr['trigger_dep'].each do |dep|
              dependency = Hash.new
              dependency['triggerid'] = zbx.triggers.get_id(:description => dep)
              dependencies.push(dependency)
            end
          end
          #
          # By default trigger is enabled which can be overwritten through attributes file
          #
          trigger_status = 0
          if trigger_attr.attribute?(:trigger_enable)
            if trigger_attr['trigger_enable']
              trigger_status = 0
            else
              trigger_status = 1
            end
          end
          if (trigger_id = zbx.triggers.get_id(:description => "#{trigger_attr['trigger_name']}")).nil?
            Chef::Log.debug "Trigger #{trigger_attr['trigger_name']} not defined"
            expr = "{"+"#{trigger_host}"+":"+"#{trigger_attr['key']}"+"."+"#{trigger_attr['trigger_val']}"+"}"+"#{trigger_attr['trigger_cond']}"
            zbx.triggers.create(:description => "#{trigger_attr['trigger_name']}", 
                                :expression => expr, 
                                :comments => trigger_attr['trigger_desc'], 
                                :priority => 4, 
                                :status => trigger_status, 
                                :dependencies => dependencies)
            cron_check_cond << "{"+"#{trigger_host}"+":"+"#{trigger_attr['key']}"+".nodata(#{node["bcpc"]["hadoop"]["zabbix"]["cron_check_time"]})}=1"
            #
            # Create an action for each trigger which will inturn execute a shell script when the trigger status turns to PROBLEM state
            #
            zbx.query(method: 'action.create', 
                      params: {"name" => "#{trigger_attr['trigger_name']}_action","eventsource" =>  0,"evaltype" => 1,"status" =>  0,"esc_period" => 120, 
                      'conditions' => [{"conditiontype" => 3,"operator" => 2,"value" => "#{trigger_attr['trigger_name']}"}, 
                                       {"conditiontype" => 5,"operator" => 0,"value" => 1}, 
                                       {"conditiontype" => 16,"operator" => 7}], 
                      'operations' => [{"operationtype" => 1,"opcommand" => {"command" => "#{node['bcpc']['zabbix']['scripts']['mail']} {TRIGGER.NAME} #{node.chef_environment} #{trigger_attr['severity']} '#{trigger_attr['trigger_desc']}' #{trigger_host} #{trigger_attr['route_to']}" ,"type" => "0","execute_on" => "1"},
                      "opcommand_hst" => [ "hostid" => 0]}]})
          else
            Chef::Log.debug "Trigger #{trigger_attr['trigger_name']} already defined"
            zbx.triggers.update(:triggerid => trigger_id, :expression => expr, :comments => "Service down", :priority => 4, :status => trigger_status, :dependencies => dependencies)
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
