include_recipe "bcpc-hadoop::graphite_queries"

template node['bcpc']['zabbix']['scripts']['sender'] do
  source "zabbix.run_zabbix_sender.sh.erb"
  owner 'zabbix'
  mode 0550
end

directory ::File.dirname(node['bcpc']['zabbix']['scripts']['mail']) do
  recursive true
  owner 'root'
end

template node['bcpc']['zabbix']['scripts']['mail'] do
  source node["bcpc"]["hadoop"]["zabbix"]["mail_source"]
  cookbook node["bcpc"]["hadoop"]["zabbix"]["cookbook"] if
    node["bcpc"]["hadoop"]["zabbix"]["cookbook"]
  mode 0755
end

template node['bcpc']['zabbix']['scripts']['query_graphite'] do
  source "graphite.query_graphite.py.erb"
  variables(:log_file => node[:bcpc][:hadoop][:zabbix][:query_graphite][:log_file],
            :config_file => node[:bcpc][:hadoop][:zabbix][:query_graphite][:config_file],
            :log_level => node[:bcpc][:hadoop][:zabbix][:query_graphite][:logging_level],
            :max_bytes => node[:bcpc][:hadoop][:zabbix][:query_graphite][:rolling_max_bytes],
            :backup_count => node[:bcpc][:hadoop][:zabbix][:query_graphite][:rolling_backup_count],
            :graphite_url => "https://#{node['bcpc']['management']['vip']}:#{node[:bcpc][:graphite][:web_port]}",
            :metric_fetch_period => node[:bcpc][:hadoop][:graphite][:metric_fetch_period],
            :worker_count => node[:bcpc][:hadoop][:graphite][:worker_count]
           )
  mode 0744
  owner "root"
  group "root"
end

template node[:bcpc][:hadoop][:zabbix][:query_graphite][:config_file] do
  source "graphite.query_graphite.config.erb"
  mode 0544
  zabbix_triggers = node.run_state["zabbix_triggers"] or {}
  variables(:queries => zabbix_triggers.map{ |host,item| item.map{ |key, attr| attr['query'] }}.flatten.to_set )
end

ruby_block "zabbix_monitor" do
  block do
    require 'zabbixapi'

    # Make connection to zabbix api url
    zbx = ZabbixApi.connect(
      :url => "https://#{node['bcpc']['management']['vip']}" +
        ":#{node['bcpc']['zabbix']['web_port']}/api_jsonrpc.php",
      :user => 'admin',
      :password => "#{get_config!('password','zabbix-admin','os')}"
    )
    if zbx.nil?
      Chef::Log.error("Could not connect to Zabbix server")
      raise "Could not connect to Zabbix server"
    end

    # Fetch graphite hosts
    graphite_hosts = get_node_attributes(
      MGMT_IP_ATTR_SRCH_KEYS, "graphite", "bcpc"
    ).map { |v| v['mgmt_ip'] }.join(",")

    if graphite_hosts.empty?
      Chef::Log.error("No graphite hosts found")
      raise "No graphite hosts found"
    end

    trapper_hosts = graphite_hosts + "," + node[:bcpc][:management][:vip]

    #cron_check_cond = Array.new

    # Create zabbix host group same as the chef environment name
    hostgroup_id = zbx.hostgroups.get_id(:name => "#{node.chef_environment}")
    if hostgroup_id.nil?
      hostgroup_id = zbx.hostgroups.create(:name => "#{node.chef_environment}")

      # Permission Guests usergroup to read hostgroup_id
      guests_ugroup_id = zbx.usergroups.get_id(:name => 'Guests')
      if guests_ugroup_id.nil?
        Chef::Log.info("Could not find 'Guests' user group in zabbix")
      else
        ret = zbx.usergroups.set_perms(
                :usrgrpid => guests_ugroup_id, :hostgroupids => [hostgroup_id], 
                :permission => 2)
        if ret.nil?
          Chef::Log.info("Failed to permission 'Guests' to read #{node.chef_environment}")
        end
      end   
    end #if hostgroup_id.nil?

    # Get existing actions
    actions = zbx.query(
      method: 'action.get',
      params: { "output" => ["actionid", "name"] }
    )
    existing_actions = actions.inject({}) {
      |result, element| result.merge({element["name"] => element["actionid"]})
    }

    zabbix_triggers = node.run_state["zabbix_triggers"] or {}
    zabbix_triggers.each do |trigger_host, queries|
      # Create host entries in Zabbix.
      # Note: these are dummy entries to define the required items and triggers
      host_id = zbx.hosts.get_id(:host => "#{trigger_host}")
      if host_id.nil?
        host_id = zbx.hosts.create(
          :host => "#{trigger_host}",
          :interfaces => [{
            :type => 1, :main => 1, :ip => '127.0.0.1', :dns => '127.0.0.1',
            :port => 10050, :useip => 0
          }],
          :groups => [:groupid => "#{hostgroup_id}"]
        )
      end

      # Define application which is used to group items
      # FIXME:
      # Following zbx.applications.create only adds the first host to the
      # application. The items that are created latest are not added to the
      # application. To add them one has to specify "attributes =>
      # [ "<zabbix id for hadoop application>" ]" to zbx.items.create_or_update
      # call but when tried it failed complaining that application hadoop is not
      # available on the host. This is for all the hosts other than the first
      # one which was passed in while creating the application.
      app_id = zbx.applications.get_id(:name => "hadoop")
      if app_id.nil?
        app_id = zbx.applications.create(
          :name => "hadoop",
          :hostid => "#{host_id}"
        )
      end

      # Get existing items for the host
      items = zbx.query(
        method: 'item.get',
        params: { "output" => ["itemid", "name"], "hostids" => host_id }
      )
      existing_items = items.inject({}) {
        |result, element| result.merge(
          { element["name"] => element["itemid"] }
        )
      }
      createItemsArr = []
      updateItemsArr = []

      # Get existing triggers for the host
      triggers = zbx.query(
        method: 'trigger.get',
        params: {
          "output" => ["triggerid", "description"],
          "hostids" => host_id
        }
      )
      existing_triggers = triggers.inject({}) {
        |result, element| result.merge(
          { element["description"] => element["triggerid"] }
        )
      }
      createTriggersArr = []
      updateTriggersArr = []

      createActionsArr = []
      updateActionsArr = []

      queries.each do |trigger_key, attrs|
        # Create zabbix items for each hosts which will accept data from
        # zabbix sender processes.
        # For details about the parameter values refer to Zabbix documentaton
        # https://www.zabbix.com/documentation/2.2/manual/api/reference/item
        if attrs['value_type'].nil?
          value_type = 3 # default = numeric unsigned
        else
          value_type = attrs['value_type']
        end

        # By default an item and its trigger & actions are disabled, which can
        # be overwritten through attributes file.
        # Per Zabbix API: status=1 => disable and status=0 => enable
        status = 1
        if attrs.key?('enable') and attrs['enable']
          status = 0
        end

        item_info = {
          :name => trigger_key, :description => trigger_key,
          :key_ => trigger_key, :type => 2, :value_type => value_type,
          :data_type => 0, :hostid => "#{host_id}", 
          :trapper_hosts => trapper_hosts, :status => status
        }

        if (item_id = existing_items[trigger_key]).nil?
          createItemsArr.push(item_info)
        else
          item_info[:itemid] = item_id
          updateItemsArr.push(item_info)
        end

        if attrs['trigger_name'].nil?
          next
        end

        # Create zabbix triggers on the items so that actions can be taken if
        # a trigger event occurs
        if attrs.key?('trigger_dep')
          dependencies = Array.new
          attrs['trigger_dep'].each do |dep|
            dep_id = zbx.triggers.get_id(:description => dep)
            if not dep_id.nil?
              dependencies.push({'triggerid' => dep_id})
            end
          end
        end

        trigger_name = attrs['trigger_name']
        expr = "{" + "#{trigger_host}" + ":" + trigger_key + "." +
          "#{attrs['trigger_val']}" + "}" + "#{attrs['trigger_cond']}"

        trigger_info = {
          :description => trigger_name,
          :expression => expr,
          :comments => attrs['trigger_desc'],
          :priority => attrs['severity'],
          :status => status,
          :dependencies => dependencies
        }
        if (trigger_id = existing_triggers[trigger_name]).nil?
          createTriggersArr.push(trigger_info)

          # For all triggers, a companion trigger is created to check whether
          # the zabbix sender cron job is active and sends data to Zabbix.
          #cron_check_cond << "{" + "#{trigger_host}" + ":" + trigger_key +
          #  ".nodata(#{node["bcpc"]["hadoop"]["zabbix"]["cron_check_time"]})}=1"
        else
          trigger_info[:triggerid] = trigger_id
          updateTriggersArr.push(trigger_info)
        end # End of "if (trigger_id = existing_triggers[trigger_name]).nil?"

        # Create/Update Actions
        action_status = node[:bcpc][:hadoop][:zabbix][:enable_alarming] ? status : 1
        esc_period = attrs['esc_period'].nil? ? node[:bcpc][:hadoop][:zabbix][:escalation_period] : attrs['esc_period']

        action_info = {
          'status' => action_status, 'esc_period' => esc_period,
          'filter'=> {  
            'evaltype' => 1,
            'conditions' => [
              {"conditiontype" => 3,"operator" => 2,"value" => trigger_name},
              {"conditiontype" => 5,"operator" => 0,"value" => 1},
              {"conditiontype" => 16,"operator" => 7, "value" => ''}
            ]
          },
          'operations' => [{
            "operationtype" => 1, "esc_step_from" => 2, "esc_step_to" => 2,
            "opcommand" => {
              "command" => "#{node['bcpc']['zabbix']['scripts']['mail']}" +
                " {TRIGGER.NAME} #{node.chef_environment}" +
                " #{attrs['severity']} '#{attrs['trigger_desc']}'" +
                " #{trigger_host} #{attrs['route_to']}",
              "type" => "0", "execute_on" => "1"
            },
            "opcommand_hst" => ["hostid" => 0]
          }]
        }
        if (action_id = existing_actions["#{trigger_name}_action"]).nil?
          action_info[:name] = "#{trigger_name}_action"
          action_info[:eventsource] = 0  
          createActionsArr.push(action_info)
        else
          action_info[:actionid] = action_id
          updateActionsArr.push(action_info)
        end # "if (action_id = existing_actions["#{trigger_name}_action"]).nil?"
      end #queries.each

      zbx.query(method: 'item.create', params: createItemsArr) if not createItemsArr.empty?
      zbx.query(method: 'item.update', params: updateItemsArr) if not updateItemsArr.empty?
      zbx.query(method: 'trigger.create', params: createTriggersArr) if not createTriggersArr.empty?
      zbx.query(method: 'trigger.update', params: updateTriggersArr) if not updateTriggersArr.empty?
      zbx.query(method: 'action.create', params: createActionsArr) if not createActionsArr.empty?
      zbx.query(method: 'action.update', params: updateActionsArr) if not updateActionsArr.empty?

    end #node["bcpc"]["hadoop"]["graphite"]["queries"].each

    # Create a dummy trigger using all the items defined during the first run
    # of this recipe to perform cron status check
    # Change reverted back due to issue
    # https://www.zabbix.com/forum/showthread.php?t=46276
    #
    #if zbx.triggers.get_id(:description => "cron_check").nil?
    #  Chef::Log.debug "Trigger cron_check not defined"
    #  cron_check_expr = cron_check_cond.join("&")
    #  zbx.triggers.create(
    #    :description => "cron_check", :expression => cron_check_expr,
    #    :comments => "Cron down", :priority => 4, :status => 0
    #  )
    #else
    #  Chef::Log.debug "Trigger cron_check already defined"
    #end
  end
  only_if { is_zabbix_leader?(node[:hostname]) }
end

cron "Run script to query graphite and send data to zabbix" do
  minute '*'
  hour   '*'
  user   'zabbix'
  command  "pgrep -u zabbix 'zabbix_sender' > /dev/null || /usr/local/bin/run_zabbix_sender.sh"
end
