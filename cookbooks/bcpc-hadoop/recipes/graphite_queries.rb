# Get a list of cluster nodes to monitor
cluster_nodes_objs = get_all_nodes.select do |nn|
  begin
    !nn['hostname'].include?('bootstrap')
  rescue
    nil
  end
end.compact

graphite_query_time = "#{node["bcpc"]["hadoop"]["zabbix"]["graphite_query_time"]}m"
triggers_sensitivity = "#{node["bcpc"]["hadoop"]["zabbix"]["triggers_sensitivity"]}m"

head_nodes_objs = get_head_nodes

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
      'query' => 'chef.*.success',
      'query_range' => '-10min',
      'trigger_val' => "max(#{node["bcpc"]["hadoop"]["zabbix"]["chef_client_check_interval"]})",
      'trigger_cond' => '=0',
      'trigger_name' => 'bcpc-bootstrap_ChefClientNotRun',
      'enable' => true,
      'trigger_desc' => 'Chef-client has not run in 30m',
      'severity' => 2,
      'route_to' => 'admin'
    }
  },
  'graphite-to-zabbix' => {
    'graphite-to-zabbix.QueryResultEmpty' => {
      'query' => 'graphite-to-zabbix.QueryResultEmpty',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => '=1',
      'trigger_name' => 'graphite-to-zabbix_QueryResultEmpty',
      'enable' => true,
      'trigger_desc' => 'Graphite to zabbix query got empty result',
      'severity' => 4,
      'route_to' => 'admin',
      'is_graphite_query' => false
    },
    'graphite-to-zabbix.QueryResultError' => {
      'query' => 'graphite-to-zabbix.QueryResultError',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => '=1',
      'trigger_name' => 'graphite-to-zabbix_QueryResultError',
      'enable' => true,
      'trigger_desc' => 'Graphite to zabbix query returned an error',
      'severity' => 4,
      'route_to' => 'admin',
      'is_graphite_query' => false
    },
    'graphite-to-zabbix.QueryResultFormatError' => {
      'query' => 'graphite-to-zabbix.QueryResultFormatError',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => '=1',
      'trigger_name' => 'graphite-to-zabbix_QueryResultFormatError',
      'enable' => true,
      'trigger_desc' => 'Graphite to zabbix query result could not be formatted',
      'severity' => 4,
      'route_to' => 'admin',
      'is_graphite_query' => false
    }
  }
}

def monitor_disk(triggers_host, host, disk, size, triggers_sensitivity)
  if triggers_host["#{host}.diskspace.#{disk}.byte_avail"].nil?
    triggers_host["#{host}.diskspace.#{disk}.byte_avail"] = {
      'query' => 'servers.*.diskspace.*.byte_avail',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => '=0',
      'trigger_name' => "#{host}_#{disk}_Availability",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => 'Disk seems to be full or down',
      'severity' => 3,
      'route_to' => 'admin'
    }
  end

  if triggers_host["#{host}.diskspace.#{disk}.byte_used"].nil?
    triggers_host["#{host}.diskspace.#{disk}.byte_used"] = {
      'query' => 'servers.*.diskspace.*.byte_used',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => ">#{(size * 0.90).ceil}G",
      'trigger_name' => "#{host}_#{disk}_SpaceUsed",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => 'More than 90% of disk space used',
      'severity' => 3,
      'route_to' => 'tenant'
    }
  end
end

def format_disk_size_hash(disk_size_hash)
  # Format the mount names like diamond (https://github.com/python-diamond/..
  # ..Diamond/blob/master/src/collectors/diskspace/diskspace.py#L196-L197)
  # and convert size to GB
  disk_size_hash.map { |mount, kb_size|
    tmp = mount.tr('/', '_').tr('.', '_').tr('\\', '')
    [tmp == '_' ? 'root' : tmp, (kb_size.to_f / 1024.0 / 1024.0).round(2)]
  }
end

cluster_nodes_objs.each do |node_obj|
  host = node_obj.hostname
  # Copy overrrides
  if !node_obj['bcpc']['hadoop']['graphite'].nil? &&
     !node_obj['bcpc']['hadoop']['graphite']['basic_queries'].nil? &&
     !node_obj['bcpc']['hadoop']['graphite']['basic_queries'].empty?
    triggers[host] = node_obj['bcpc']['hadoop']['graphite']['basic_queries'].dup
  else
    triggers[host] = {}
  end

  # Selectively add defaults
  if triggers[host]["memory_active_#{host}"].nil?
    triggers[host]["#{host}.memory.Active"] = {
      'query' => 'servers.*.memory.Active',
      'trigger_val' => "max(#{triggers_sensitivity})",
      'trigger_cond' => '=0',
      'trigger_name' => "#{host}_NodeAvailability",
      'enable' => true,
      'trigger_desc' => 'Node seems to be down',
      'severity' => 3,
      'route_to' => 'admin'
    }
  end
  if triggers[host]["chef_client_success_#{host}"].nil?
    triggers[host]["chef.#{host}.success"] = {
      'query' => 'chef.*.success',
      'query_range' => '-10min',
      'trigger_val' => "max(#{node['bcpc']['hadoop']['zabbix']['chef_client_check_interval']})",
      'trigger_cond' => '=0',
      'trigger_name' => "#{host}_ChefClientNotRun",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => "Chef-client has not run in #{node['bcpc']['hadoop']['zabbix']['chef_client_check_interval']}",
      'severity' => 1,
      'route_to' => 'admin'
    }
  end
  if triggers[host]["chef_client_fail_#{host}"].nil?
    triggers[host]["chef.#{host}.fail"] = {
      'query' => 'chef.*.fail',
      'query_range' => '-10min',
      'trigger_val' => 'max(' + node['bcpc']['hadoop']['zabbix']['chef_client_check_interval'].to_s + ')',
      'trigger_cond' => '=1',
      'trigger_name' => "#{host}_ChefClientFailure",
      'trigger_dep' => ["#{host}_NodeAvailability"],
      'enable' => true,
      'trigger_desc' => 'Chef-client failed',
      'severity' => 1,
      'route_to' => 'admin'
    }
  end

  # Fetch disks for this node.
  # Use the same logic as diamond (https://github.com/python-diamond/Diamond/..
  # ..blob/master/src/collectors/diskspace/diskspace.py#L137-L165)
  # to filter out unwanted disks/mounts
  disk_size_hash = node_obj.filesystem
                           .map { |_fs, props| [props['mount'], props['kb_size']] }.compact.uniq

  # monitor only the root for all the cluster nodes
  disk_size_hash = disk_size_hash.reject { |_mount, kb_size| kb_size.nil? }
                                 .keep_if { |mount, _kb_size| mount.eql?('/') }

  disk_size_hash = format_disk_size_hash(disk_size_hash)

  # add to triggers
  disk_size_hash.each do |disk, size|
    monitor_disk(triggers[host], host, disk, size, triggers_sensitivity)
  end

  # Copy service specific queries
  if !node_obj['bcpc']['hadoop']['graphite'].nil? &&
     !node_obj['bcpc']['hadoop']['graphite']['service_queries'].nil? &&
     !node_obj['bcpc']['hadoop']['graphite']['service_queries'].empty?
    node_obj['bcpc']['hadoop']['graphite']['service_queries'].each do |s_host, _s_query|
      triggers[s_host] = node_obj['bcpc']['hadoop']['graphite']['service_queries'][s_host]
    end
  end
end # End of 'monitored_nodes_objs.each do |node_obj|'

# monitor all disks on head nodes
head_nodes_objs.each do |head_node_obj|
  host = head_node_obj.hostname

  disk_size_hash = head_node_obj.filesystem
                                .map { |_fs, props| [props['mount'], props['kb_size']] }.compact.uniq

  # monitor all disks for head nodes
  disk_size_hash = disk_size_hash.reject { |_mount, kb_size| kb_size.nil? }
                                 .keep_if { |mount, _kb_size| mount.start_with?('/disk') }

  disk_size_hash = format_disk_size_hash(disk_size_hash)

  # add to triggers
  disk_size_hash.each do |disk, size|
    monitor_disk(triggers[host], host, disk, size, triggers_sensitivity)
  end
end

# Save the trigger information in node's run_state so it is available for
# the recipe which creates objects in Zabbix
node.run_state['zabbix_triggers'] = triggers
