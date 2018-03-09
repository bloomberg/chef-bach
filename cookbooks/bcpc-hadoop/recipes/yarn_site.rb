if node['bcpc']['hadoop']['yarn']['yarn.log-aggregation.retain-days'] == -1
  node.default['bcpc']['hadoop']['yarn']['site_xml']['yarn.log-aggregation.retain-seconds'] = -1
else
  node.default['bcpc']['hadoop']['yarn']['site_xml']['yarn.log-aggregation.retain-seconds'] =
    60 * 60 * 24 * node['bcpc']['hadoop']['yarn']['yarn.log-aggregation.retain-days']
end

yarn_site_values = node[:bcpc][:hadoop][:yarn][:site_xml]
node.run_state[:yarn_site_generated_values] = {}

node.default[:bcpc][:hadoop][:yarn][:aux_services][:mapreduce_shuffle][:class] =
  'org.apache.hadoop.mapred.ShuffleHandler'

if node.run_list.expand(node.chef_environment).recipes
    .include?('bach_spark::default')
  node.default[:bcpc][:hadoop][:yarn][:aux_services][:spark_shuffle][:class] =
    'org.apache.spark.network.yarn.YarnShuffleService'
end

yarn_aux_services =
  node[:bcpc][:hadoop][:yarn][:aux_services].map do |k, cls_v|
  { "yarn.nodemanager.aux-services.#{k}.class" => cls_v['class'] }
end.reduce({},:merge)
node.run_state[:yarn_site_generated_values].merge!(yarn_aux_services)

#
# ResourceManager and Zookeeper host objects
#
# These are retrieved from the server and inserted into the node object
# at run time.
#
rm_hosts = node[:bcpc][:hadoop][:rm_hosts]
zk_hosts = node[:bcpc][:hadoop][:zookeeper][:servers]

# If we have two or more ResourceManager hosts, we need to add HA
# properties to yarn-site.
if rm_hosts.length >= 2
  rm_properties =
    {
     'yarn.client.failover-sleep-base-ms' => 150,
     'yarn.client.failover-proxy-provider' =>
       'org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider',
     'yarn.resourcemanager.cluster-id' => node.chef_environment,
     'yarn.resourcemanager.ha.enabled' => true,
     'yarn.resourcemanager.ha.rm-ids' =>
       rm_hosts.map{ |h| "rm#{node.chef_environment}#{h[:node_number]}" }
       .join(","),
     'yarn.resourcemanager.recovery.enabled' => true,
     'yarn.resourcemanager.store.class' =>
       'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore',
     'yarn.resourcemanager.zk-address' =>
       zk_hosts.map{ |h| float_host(h[:hostname]) +
         ":#{node[:bcpc][:hadoop][:zookeeper][:port]}"}
       .join(',')
    }

  # Using 'map', a hash is built for each host.
  # Using 'reduce', all host hashes are consolidated into a single hash.
  rm_nodes = rm_hosts.map{ |h|
    rm_name = "rm#{node.chef_environment}#{h[:node_number]}"
    rm_target = float_host(h[:hostname])
    {
      'yarn.resourcemanager.hostname.' + rm_name =>
        rm_target,
        'yarn.resourcemanager.resource-tracker.address.' + rm_name =>
        rm_target + ':8031',
        'yarn.resourcemanager.address.' + rm_name =>
        rm_target + ':' +
        node["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["port"].to_s,
        'yarn.resourcemanager.scheduler.address.' + rm_name =>
        rm_target + ':8030',
        'yarn.resourcemanager.admin.address.' + rm_name =>
        rm_target + ':8033',
        'yarn.resourcemanager.webapp.address.' + rm_name =>
        rm_target + ':8088',
        'yarn.resourcemanager.webapp.https.address.' + rm_name =>
        rm_target + ':8090',
    }
  }.reduce({},:merge)
  # Finally, the single hash is merged into rm_properties.
  rm_properties.merge!(rm_nodes)

  node.run_state[:yarn_site_generated_values].merge!(rm_properties)

  # If the node search found no ResourceManagers at all, insert no values.
elsif rm_hosts.empty?
  rm_properties =
    {
     'yarn.resourcemanager.address' => '',
     'yarn.resourcemanager.admin.address' => '',
     'yarn.resourcemanager.resource-tracker.address' => '',
     'yarn.resourcemanager.scheduler.address' => '',
     'yarn.resourcemanager.webapp.address' => '',
     'yarn.resourcemanager.webapp.https.address' => '',
    }
  node.run_state[:yarn_site_generated_values].merge!(rm_properties)

  # If we have fewer than two RMs, but more than none, insert non-HA properties.
else
  rm_target = float_host(rm_hosts.first[:hostname])
  rm_properties =
    {
     'yarn.resourcemanager.address' =>
       rm_target + ':' +
       node["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["port"].to_s,
     'yarn.resourcemanager.admin.address' =>
       "#{rm_target}:8033",
     'yarn.resourcemanager.resource-tracker.address' =>
       "#{rm_target}:8031",
     'yarn.resourcemanager.scheduler.address' =>
       "#{rm_target}:8030",
     'yarn.resourcemanager.webapp.address' =>
       "#{rm_target}:8088",
     'yarn.resourcemanager.webapp.https.address' =>
       "#{rm_target}:8090",
    }
  node.run_state[:yarn_site_generated_values].merge!(rm_properties)
end

if node.run_list.expand(node.chef_environment).recipes
    .include?('bcpc-hadoop::datanode')

  nm_properties =
    {
     'yarn.nodemanager.recovery.enabled' => true,

     'yarn.nodemanager.address' =>
       float_host(node[:hostname]) + ':' +
       node["bcpc"]["hadoop"]["yarn"]["nodemanager"]["port"].to_s,

     'yarn.nodemanager.bind-host' =>
       float_host(node[:fqdn]),

     'yarn.nodemanager.hostname' =>
       float_host(node[:fqdn]),
    }


  node.run_state[:yarn_site_generated_values].merge!(nm_properties)
end

if node.run_list.expand(node.chef_environment).recipes
    .include?('bcpc-hadoop::resource_manager')

  rm_properties =
    {
     'yarn.resourcemanager.bind-host' =>
       float_host(node[:fqdn]),
    }

  node.run_state[:yarn_site_generated_values].merge!(rm_properties)
end

if node[:bcpc][:hadoop][:kerberos][:enable]
  kerberos_properties =
    {
     'yarn.nodemanager.keytab' =>
       node[:bcpc][:hadoop][:kerberos][:keytab][:dir] + '/' +
       node[:bcpc][:hadoop][:kerberos][:data][:nodemanager][:keytab],

     'yarn.resourcemanager.keytab' =>
       node[:bcpc][:hadoop][:kerberos][:keytab][:dir] + '/' +
       node[:bcpc][:hadoop][:kerberos][:data][:resourcemanager][:keytab],

     'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled' =>
       true,
    }

  kerberos_data = node[:bcpc][:hadoop][:kerberos][:data]

  if kerberos_data[:nodemanager][:princhost] == '_HOST'
    kerberos_host = if node.run_list.expand(node.chef_environment).recipes
                        .include?('bcpc-hadoop::datanode')
                      float_host(node[:fqdn])
                    else
                      '_HOST'
                    end
  else
    kerberos_host = kerberos_data[:nodemanager][:princhost]
  end

  nm_kerberos_principal =
    kerberos_data[:nodemanager][:principal] + '/' + kerberos_host + '@' +
    node[:bcpc][:hadoop][:kerberos][:realm]

  if kerberos_data[:resourcemanager][:princhost] == '_HOST'
    kerberos_host = '_HOST'
  else
    kerberos_host = kerberos_data[:resourcemanager][:princhost]
  end

  rm_kerberos_principal =
    kerberos_data[:resourcemanager][:principal] + '/' + kerberos_host + '@' +
    node[:bcpc][:hadoop][:kerberos][:realm]

  node.run_state[:yarn_site_generated_values].merge!({'yarn.nodemanager.principal' =>
                                                      nm_kerberos_principal})

  node.run_state[:yarn_site_generated_values].merge!({'yarn.resourcemanager.principal' =>
                                                      rm_kerberos_principal})

  node.run_state[:yarn_site_generated_values].merge!(kerberos_properties)
end

# configure yarn timeline server
if node.roles.include?("BCPC-Hadoop-Head-YarnTimeLineServer")
  if kerberos_data[:resourcemanager][:princhost] == '_HOST'
    kerberos_host = '_HOST'
  else
    kerberos_host = kerberos_data[:resourcemanager][:princhost]
  end

  rm_kerberos_principal =
    kerberos_data[:resourcemanager][:principal] + '/' + kerberos_host + '@' +
    node[:bcpc][:hadoop][:kerberos][:realm]

  yts_properties =
    {
      'yarn.timeline-service.version' => 1.5,
      'yarn.timeline-service.store-class' => 'org.apache.hadoop.yarn.server.timeline.EntityGroupFSTimelineStore',
      'yarn.timeline-service.entity-group-fs-store.active-dir' => "/var/log/ats/active",
      'yarn.timeline-service.entity-group-fs-store.done-dir' => "/var/log/ats/done",
      'yarn.timeline-service.entity-group-fs-store.group-id-plugin-classes' => "org.apache.tez.dag.history.logging.ats.TimelineCachePluginImpl",
      'yarn.timeline-service.entity-group-fs-store.summary-store' => "org.apache.hadoop.yarn.server.timeline.RollingLevelDBTimelineStore",
      'yarn.timeline-service.hostname' => "#{float_host(node.fqdn)}",
      'yarn.timeline-service.address' => "#{float_host(node.fqdn)}:10200",
      'yarn.timeline-service.webapp.address' =>  "#{float_host(node.fqdn)}:8188",
      'yarn.timeline-service.bind-host' => "#{float_host(node.fqdn)}",
      'yarn.timeline-service.handler-thread-count' => 10,
      'yarn.resourcemanager.system-metrics-publisher.enabled' => true,
      'yarn.timeline-service.generic-application-history.enabled' => true,
      'yarn.timeline-service.enabled' => true,
      'yarn.timeline-service.ttl-enable' => true,
      'yarn.timeline-service.principal' => rm_kerberos_principal,
      'yarn.timeline-service.keytab' =>
        node[:bcpc][:hadoop][:kerberos][:keytab][:dir] + '/' +
        node[:bcpc][:hadoop][:kerberos][:data][:resourcemanager][:keytab],
      'yarn.timeline-service.http-authentication.type' => "kerberos",
      'yarn.timeline-service.http-authentication.kerberos.principal' => "HTTP/#{kerberos_host}@#{node["bcpc"]["hadoop"]["kerberos"]["realm"] }",
      'yarn.timeline-service.http-authentication.kerberos.keytab' =>
        node[:bcpc][:hadoop][:kerberos][:keytab][:dir] + '/' +
        node[:bcpc][:hadoop][:kerberos][:data][:resourcemanager][:spnego_keytab],
   }
  node.run_state[:yarn_site_generated_values].merge!(yts_properties)
end

# This is another set of cached node searches.
hs_hosts = node[:bcpc][:hadoop][:hs_hosts]
if not hs_hosts.empty?
  yarn_log_server_url =    'http://' +
    float_host(hs_hosts.map{ |h| h[:hostname] }.sort.first) +
    ':19888' + '/jobhistory/logs'

  node.run_state[:yarn_site_generated_values].merge!({'yarn.log.server.url' =>
                                                      yarn_log_server_url})
end

ruby_block 'yarn_site_generated_values' do
  block do
    mounts = node.run_state['bcpc_hadoop_disks']['mounts']
    directory_values =
    {
     'yarn.nodemanager.local-dirs' =>
       mounts.map{ |d| "/disk/#{d}/yarn/local" }.join(','),

     'yarn.nodemanager.log-dirs' =>
       mounts.map{ |d| "/disk/#{d}/yarn/logs" }.join(','),

     'yarn.nodemanager.aux-services' =>
       node[:bcpc][:hadoop][:yarn][:aux_services].keys.join(','),

     'yarn.scheduler.minimum-allocation-mb' =>
       node['bcpc']['hadoop']['yarn']['scheduler']['minimum-allocation-mb']
    }
    node.run_state[:yarn_site_generated_values].merge!(directory_values)

    # At this point, the complete set of values is in this run_state var.
    node.run_state[:yarn_site_generated_values].merge!(yarn_site_values)
  end
end

template '/etc/hadoop/conf/yarn-site.xml' do
  source 'generic_site.xml.erb'
  mode 0644
  variables lazy{{ options: node.run_state[:yarn_site_generated_values]}}
end
