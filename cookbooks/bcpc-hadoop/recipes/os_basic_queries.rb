# Get a list of cluster nodes to monitor
monitored_nodes_objs = get_all_nodes.map { |n| n if not n.hostname =~ /bootstrap/ }.compact

# Graphite queries which specify property to query and alarming trigger, severity(maps to zabbix's api -> trigger -> priority)
# and owner who the trigger is routed to for resolution
# Queries are structured as they appear in graphite dashboard
# Refer Zabbix API(https://www.zabbix.com/documentation/2.2/manual/api/reference/) for the various attributes used
# The following list is supposed to be a skeleton which should be extended/edited according to the deployment scenario
# By default items, triggers actions are disabled and won't be monitored. To enable them, set "enable=true" in the json structure
monitored_nodes_objs.each do |node_obj|
  host = node_obj.hostname
  node.default["bcpc"]["hadoop"]["graphite"]["queries"]["#{host}"] = { 
      "memory_active_#{host}" => {
        'type' => "servers",
        'query' => "memory.Active",
        'trigger_val' => "max(61,0)",
        'trigger_cond' => "=0",
        'trigger_name' => "#{host}_NodeAvailability",
        'enable' => true,
        'trigger_desc' => "Node seems to be down",
        'severity' => 5,
        'route_to' => "admin"
      },
      "chef_client_success_#{host}" => {
        'type' => "chef",
        'query' => "success",
        'trigger_val' => "max(#{((node['chef_client']['interval'].to_i + node['chef_client']['splay'].to_i) / 30).ceil}m, 0)",
        'value_type' => 3,
        'trigger_cond' => "=0",
        'trigger_name' => "#{host}_ChefClientSuccess",
        'trigger_dep' => ["#{host}_NodeAvailability"],
        'enable' => true,
        'trigger_desc' => "Chef-client seems to be failing/stopped",
        'severity' => 1,
        'route_to' => "admin"
      }
  }

  # Fetch disks for this node.
  # Use the same logic as diamond(https://github.com/python-diamond/Diamond/blob/master/src/collectors/diskspace/diskspace.py#L137-L165)
  # to filter out unwanted disks/mounts
  disk_size_hash = node_obj.filesystem.map { |fs,props| [props['mount'],props['kb_size']] }.compact.uniq
  disk_size_hash = disk_size_hash.reject{ |mount,kb_size| kb_size.nil? }.reject{ |mount,kb_size| mount.start_with?('/dev') || mount.start_with?('/sys') || mount.start_with?('/proc') || mount.start_with?('/run') || mount.start_with?('/boot') }
  # Format the mount names like diamond(https://github.com/python-diamond/Diamond/blob/master/src/collectors/diskspace/diskspace.py#L196-L197) and convert size to GB
  disk_size_hash = disk_size_hash.map{ |mount,kb_size| tmp = mount.gsub('/', '_').gsub('.', '_').gsub('\\', ''); [tmp == '_' ? 'root':tmp, (kb_size.to_i / 1024 / 1024).ceil] }
  
  disk_size_hash.each do |disk,size|
    node.default["bcpc"]["hadoop"]["graphite"]["queries"]["#{host}"]["#{disk}_space_avail_#{host}"] = {
      'type' => "servers",
      'query' => "diskspace.#{disk}.byte_avail",
      'trigger_val' => "max(61,0)",
      'value_type' => 3,
      'trigger_cond' => "=0",
      'trigger_name' => "#{host}_#{disk}_Availability",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => "Disk seems to be full or down",
      'severity' => 4,
      'route_to' => "admin"
    }
    
    node.default["bcpc"]["hadoop"]["graphite"]["queries"]["#{host}"]["#{disk}_space_used_75_#{host}"] = {
      'type' => "servers",
      'query' => "diskspace.#{disk}.byte_used",
      'trigger_val' => "max(61,0)",
      'value_type' => 3,
      'trigger_cond' => ">#{(size * 0.75).floor}G",
      'trigger_name' => "#{host}_#{disk}_SpaceUsed_75",
      'enable' => true,
      'trigger_desc' => "More than 75% of disk space used",
      'severity' => 3,
      'route_to' => "tenant"
    }
  end
end
