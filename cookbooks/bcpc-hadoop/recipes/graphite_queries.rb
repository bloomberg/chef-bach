# Get a list of cluster nodes to monitor
monitored_nodes_objs = get_all_nodes.select { |n| not n.hostname =~ /bootstrap/ }.compact

# Graphite queries which specify property to query and alarming trigger,
# severity(maps to zabbix's api -> trigger -> priority)and owner who the
# trigger is routed to for resolution. Queries are structured as they appear in
# graphite dashboard.
# Refer Zabbix API(https://www.zabbix.com/documentation/2.2/manual/api/reference/)
# for the various attributes used. The following list is supposed to be a
# skeleton which should be extended/edited according to the deployment scenario
# By default items, triggers actions are disabled and won't be monitored.
# To enable them, set "enable=true" in the json structure
triggers = {
  'bcpc-bootstrap' => {
    'chef.bcpc-bootstrap.success' => {
      'query' => "chef.*.success",
      'trigger_val' => "max(30m)",
      'trigger_cond' => "=0",
      'trigger_name' => "bcpc-bootstrap_ChefClientNotRun",
      'enable' => true,
      'trigger_desc' => "Chef-client hasn't run in 30m",
      'severity' => 2,
      'route_to' => "admin"
    }
  },
  'graphite-to-zabbix' => {
    'graphite-to-zabbix.QueryResultEmpty' => {
      'query' => "graphite-to-zabbix.QueryResultEmpty",
      'trigger_val' => "min(3m)",
      'trigger_cond' => "=1",
      'trigger_name' => "graphite-to-zabbix_QueryResultEmpty",
      'enable' => true,
      'trigger_desc' => "Graphite to zabbix query got empty result",
      'severity' => 4,
      'route_to' => "admin",
      'is_graphite_query' => false
    },
    'graphite-to-zabbix.QueryResultError' => {
      'query' => "graphite-to-zabbix.QueryResultError",
      'trigger_val' => "max(3m)",
      'trigger_cond' => "=1",
      'trigger_name' => "graphite-to-zabbix_QueryResultError",
      'enable' => true,
      'trigger_desc' => "Graphite to zabbix query returned an error",
      'severity' => 4,
      'route_to' => "admin",
      'is_graphite_query' => false
    },
    'graphite-to-zabbix.QueryResultFormatError' => {
      'query' => "graphite-to-zabbix.QueryResultFormatError",
      'trigger_val' => "max(3m)",
      'trigger_cond' => "=1",
      'trigger_name' => "graphite-to-zabbix_QueryResultFormatError",
      'enable' => true,
      'trigger_desc' => "Graphite to zabbix query result could not be formatted",
      'severity' => 4,
      'route_to' => "admin",
      'is_graphite_query' => false
    }
  }
}

trigger_chk_period = "#{node["bcpc"]["hadoop"]["zabbix"]["trigger_chk_period"]}m"
monitored_nodes_objs.each do |node_obj|
  host = node_obj.hostname
  # Copy overrrides
  if not node_obj["bcpc"]["hadoop"]["graphite"].nil? and
    not node_obj["bcpc"]["hadoop"]["graphite"]["basic_queries"].nil? and
    not node_obj["bcpc"]["hadoop"]["graphite"]["basic_queries"].empty?
    triggers[host] = node_obj["bcpc"]["hadoop"]["graphite"]["basic_queries"].dup
  else
    triggers[host] = {}
  end
  
  # Selectively add defaults
  if triggers[host]["memory_active_#{host}"].nil?
    triggers[host]["#{host}.memory.Active"] = {
      'query' => "servers.*.memory.Active",
      'trigger_val' => "max(#{trigger_chk_period})",
      'trigger_cond' => "=0",
      'trigger_name' => "#{host}_NodeAvailability",
      'enable' => true,
      'trigger_desc' => "Node seems to be down",
      'severity' => 3,
      'route_to' => "admin"
    }
  end
  if triggers[host]["chef_client_success_#{host}"].nil?
    triggers[host]["chef.#{host}.success"] = {
      'query' => "chef.*.success",
      'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["chef_client_check_interval"]})",
      'trigger_cond' => "=0",
      'trigger_name' => "#{host}_ChefClientNotRun",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => "Chef-client hasn't run in #{node["bcpc"]["hadoop"]["zabbix"]["chef_client_check_interval"]}", 
      'severity' => 1,
      'route_to' => "admin"
    }
  end
  if triggers[host]["chef_client_fail_#{host}"].nil?
    triggers[host]["chef.#{host}.fail"] = {
      'query' => "chef.*.fail",
      'trigger_val' => "max(" +
        "#{node["bcpc"]["hadoop"]["zabbix"]["chef_client_check_interval"]}" +
      ")",
      'trigger_cond' => "=1",
      'trigger_name' => "#{host}_ChefClientFailure",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => "Chef-client failed",
      'severity' => 1,
      'route_to' => "admin"
    }
  end

  # Fetch disks for this node.
  # Use the same logic as diamond (https://github.com/python-diamond/Diamond/..
  # ..blob/master/src/collectors/diskspace/diskspace.py#L137-L165)
  # to filter out unwanted disks/mounts
  disk_size_hash = node_obj.filesystem
    .map { |fs,props| [props['mount'],props['kb_size']] }.compact.uniq
  disk_size_hash = disk_size_hash.reject { |mount,kb_size| kb_size.nil? }
    .reject {
      |mount,kb_size| mount.start_with?('/dev') || mount.start_with?('/sys') ||
      mount.start_with?('/proc') || mount.start_with?('/run') ||
      mount.start_with?('/boot') || mount.start_with?('/tmp')
    }

  # Format the mount names like diamond (https://github.com/python-diamond/..
  # ..Diamond/blob/master/src/collectors/diskspace/diskspace.py#L196-L197)
  # and convert size to GB
  disk_size_hash = disk_size_hash.map {
    |mount,kb_size| tmp = mount.gsub('/', '_').gsub('.', '_').gsub('\\', '');
    [tmp == '_' ? 'root':tmp, (kb_size.to_f / 1024.0 / 1024.0).round(2)]
  }

  disk_size_hash.each do |disk,size|
    if triggers[host]["#{host}.diskspace.#{disk}.byte_avail"].nil?
      triggers[host]["#{host}.diskspace.#{disk}.byte_avail"] = {
        'query' => "servers.*.diskspace.*.byte_avail",
        'trigger_val' => "max(#{trigger_chk_period})",
        'trigger_cond' => "=0",
        'trigger_name' => "#{host}_#{disk}_Availability",
        'trigger_dep' => ["#{host}_NodeAvailability"],
        'enable' => true,
        'trigger_desc' => "Disk seems to be full or down",
        'severity' => 3,
        'route_to' => "admin"
      }
    end

    if triggers[host]["#{host}.diskspace.#{disk}.byte_used"].nil?
      triggers[host]["#{host}.diskspace.#{disk}.byte_used"] = {
        'query' => "servers.*.diskspace.*.byte_used",
        'trigger_val' => "max(#{trigger_chk_period})",
        'trigger_cond' => ">#{(size * 0.90).ceil}G",
        'trigger_name' => "#{host}_#{disk}_SpaceUsed",
        'trigger_dep' => ["#{host}_NodeAvailability"],
        'enable' => true,
        'trigger_desc' => "More than 90% of disk space used",
        'severity' => 3,
        'route_to' => "tenant"
      }
    end
  end # End of "disk_size_hash.each do |disk,size|"

  # Copy service specific queries
  if not node_obj["bcpc"]["hadoop"]["graphite"].nil? and
    not node_obj["bcpc"]["hadoop"]["graphite"]["service_queries"].nil? and
    not node_obj["bcpc"]["hadoop"]["graphite"]["service_queries"].empty?
    node_obj["bcpc"]["hadoop"]["graphite"]["service_queries"].each do |s_host, s_query|
      triggers[s_host] = node_obj["bcpc"]["hadoop"]["graphite"]["service_queries"][s_host]
    end    
  end
end # End of "monitored_nodes_objs.each do |node_obj|"

# Save the trigger information in node's run_state so it is available for
# the recipe which creates objects in Zabbix
node.run_state["zabbix_triggers"] = triggers
