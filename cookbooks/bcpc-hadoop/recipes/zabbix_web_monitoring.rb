ruby_block "zabbix_web_monitoring" do
  block do
    require 'zabbixapi'

    # Make connection to zabbix api url
    zbx = ZabbixApi.connect(
      :url => "https://#{node.default[:bcpc][:hadoop][:zabbix][:server][:addr]}" +
        ":#{node[:bcpc][:hadoop][:zabbix][:server][:port]}/api_jsonrpc.php",
      :user => get_config!('zabbix-admin-user'),
      :password => "#{get_config!('password','zabbix-admin','os')}"
    )
    if zbx.nil?
      Chef::Log.error("Could not connect to Zabbix server")
      raise "Could not connect to Zabbix server"
    end

    # Create zabbix host group same as the chef environment name
    hostgroup_id = zbx.hostgroups.get_id(:name => "#{node.chef_environment}")
    if hostgroup_id.nil?
      hostgroup_id = zbx.hostgroups.create(:name => "#{node.chef_environment}")

      # Permission Guests usergroup to read hostgroup_id
      guests_ugroup_id = zbx.usergroups.get_id(:name => 'Guests')
      if guests_ugroup_id.nil?
        Chef::Log.debug("Could not find 'Guests' user group in zabbix")
      else
        ret = zbx.usergroups.set_perms(
                :usrgrpid => guests_ugroup_id, :hostgroupids => [hostgroup_id],
                :permission => 2) # 0 - access denied; 2 - read-only access; 3 - read-write access.
        if ret.nil?
          Chef::Log.debug("Failed to permission 'Guests' to read #{node.chef_environment}")
        end
      end
    end #if hostgroup_id.nil?

    # Create host for web moniroting
    host_name="web_monitoring"
    host_id = zbx.hosts.get_id(:host => "#{host_name}")
    if host_id.nil?
      host_id = zbx.hosts.create(
        :host => "#{host_name}",
        :interfaces => [{
          :type => 1, :main => 1, :ip => '127.0.0.1', :dns => '127.0.0.1',
          :port => 10050, :useip => 0
        }],
        :groups => [:groupid => "#{hostgroup_id}"]
      )
    end #if host_id.nil?

    # ------------ process global vip end points ------------
    pp "start processing global vip end points"
    gvip_end_points = node.default[:bcpc][:hadoop][:zabbix][:web_monitoring][:global_vip_endpoints]
    gvip_end_points.each do |end_point|
      pp "  start processing global vip end point #{end_point[:name]}"

      # define names for the three parts
      name_web     = "#{end_point[:name]}"
      name_trigger = "#{end_point[:name]} trigger"
      name_action  = "#{end_point[:name]} action"

      # add scenario
      zbx.httptests.create_or_update(
        :name => name_web,
        :delay => "15",
        :retries=> "5",
        :hostid => "#{host_id}",
        :steps => [{
          :no=>"1",
          :name=> name_web,
          :url => end_point[:url],
          :timeout=>"15",
          :status_codes=>"200",
          :follow_redirects=>"1",
        }]
      )

      pp("    added web scenario:" +
        zbx.httptests.get_raw( { :filter => { :name => name_web } , :selectSteps => "extend" }).to_s)


      # add triggers
      trigger_expression = "{#{host_name}:#{end_point[:trigger_item]}[#{name_web}]." +
        "#{end_point[:trigger_func]}}#{end_point[:trigger_cond]}"

      zbx.triggers.create_or_update(
        :description => name_trigger,
        :expression => trigger_expression,
        :comments => end_point[:description],
        :hostid => host_id,
        :priority => end_point[:severity],
        :status => "0", # 0 - enabled; 1 - disabled
        :type => "0"
      )

      pp("    added trigger:" +
        zbx.triggers.get_raw( { :filter => { :description => name_trigger }, :output => "extend", }).to_s)


      # add action
      action_status = node[:bcpc][:hadoop][:zabbix][:enable_alarming] ? 0 : 1 # status = 0 means enabled
      esc_period = node[:bcpc][:hadoop][:zabbix][:escalation_period]
      zbx.actions.create_or_update(
        :name => name_action,
        :eventsource => 0,
        :status => action_status,
        :esc_period => esc_period,
        :filter => {
          :evaltype => 1,
          :conditions => [
            {:conditiontype => 3, :operator => 2, :value => name_trigger},
            {:conditiontype => 5, :operator => 0, :value => 1},
            {:conditiontype => 16, :operator => 7, :value => ''}
          ]
        },
        :operations => [{
          :operationtype => 1,
          :esc_step_from => 2,
          :esc_step_to => 2,
          :opcommand => {
            :command => "#{node['bcpc']['zabbix']['scripts']['mail']}" +
              " {TRIGGER.NAME} #{node.chef_environment}" +
              " 2 '#{end_point[:description]}'" +
              " #{host_name} admin",
            :type => "0", :execute_on => "1"
          },
          :opcommand_hst => [:hostid => 0]
        }]
      )
      pp("    added action:" +
        zbx.actions.get_raw( { :filter => { :name => "HBaseMasterAvailability_action" },
        :output => "extend", :selectOperations => "extend", :selectFilter => "extend" }).to_s)
    end

    # ------------ process role based end points ------------
    pp "start processing role based end points"
    role_end_points = node.default[:bcpc][:hadoop][:zabbix][:web_monitoring][:role_based_endpoints]
    role_end_points.each do |role_end_point|
      pp "  start processing role #{role_end_point[:role]}"

      end_points = role_end_point[:end_points]
      end_points.each do |end_point|
        pp "    start processing end point #{end_point[:name]}"
        # define names for the three parts
        name_web     = "#{end_point[:name]}"
        name_trigger = "#{end_point[:name]} trigger"
        name_action  = "#{end_point[:name]} action"
      end
    end
#
#    # iterate the web scenarios and create_or_update scenarios and related triggers and actions
#    scenarios = node.default[:bcpc][:hadoop][:zabbix][:web_monitoring][:scenarios]
#    scenarios.each do | scenario |
#      Chef::Log.info("start processing web scenario #{scenario[:name]}")
#
#      # define names for the three parts
#      name_web     = "#{scenario[:name]}"
#      name_trigger = "#{scenario[:name]} trigger"
#      name_action  = "#{scenario[:name]} action"
#
#      # add scenario
#      zbx.httptests.create_or_update(
#        :name => name_web,
#        :delay => "15",
#        :retries=> "5",
#        :hostid => "#{host_id}",
#        :steps => [{
#          :no=>"1",
#          :name=> scenario[:name],
#          :url => scenario[:url],
#          :timeout=>"15",
#          :status_codes=>"200",
#          :follow_redirects=>"1",
#        }]
#      )
#
#      Chef::Log.info("added web scenario:" +
#        zbx.httptests.get_raw( { :filter => { :name => name_web } , :selectSteps => "extend" }).to_s)
#
#
#      # add triggers
#      trigger_expression = "{#{host_name}:#{scenario[:trigger_item]}[#{name_web}]." +
#        "#{scenario[:trigger_func]}}#{scenario[:trigger_cond]}"
#
#      zbx.triggers.create_or_update(
#        :description => name_trigger,
#        :expression => trigger_expression,
#        :comments => scenario[:description],
#        :hostid => host_id,
#        :priority => scenario[:severity],
#        :status => "0",
#        :type => "0"
#      )
#
#      Chef::Log.info("added trigger:" +
#        zbx.triggers.get_raw( { :filter => { :description => name_trigger }, :output => "extend", }).to_s)
#
#
#      # add action
#      action_status = node[:bcpc][:hadoop][:zabbix][:enable_alarming] ? 0 : 1 # status = 0 means enabled
#      esc_period = node[:bcpc][:hadoop][:zabbix][:escalation_period]
#      zbx.actions.create_or_update(
#        :name => name_action,
#        :eventsource => 0,
#        :status => action_status,
#        :esc_period => esc_period,
#        :filter => {
#          :evaltype => 1,
#          :conditions => [
#            {:conditiontype => 3, :operator => 2, :value => name_trigger},
#            {:conditiontype => 5, :operator => 0, :value => 1},
#            {:conditiontype => 16, :operator => 7, :value => ''}
#          ]
#        },
#        :operations => [{
#          :operationtype => 1,
#          :esc_step_from => 2,
#          :esc_step_to => 2,
#          :opcommand => {
#            :command => "#{node['bcpc']['zabbix']['scripts']['mail']}" +
#              " {TRIGGER.NAME} #{node.chef_environment}" +
#              " 2 '#{scenario[:description]}'" +
#              " #{host_name} admin",
#            :type => "0", :execute_on => "1"
#          },
#          :opcommand_hst => [:hostid => 0]
#        }]
#      )
#      Chef::Log.info("added action:" +
#        zbx.actions.get_raw( { :filter => { :name => "HBaseMasterAvailability_action" },
#        :output => "extend", :selectOperations => "extend", :selectFilter => "extend" }).to_s)
#
#    end
  end
  only_if { is_zabbix_leader?(node[:hostname]) }
end
