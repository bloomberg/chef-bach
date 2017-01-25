# vim: tabstop=2:shiftwidth=2:softtabstop=2:expandtabs
subnet = node[:bcpc][:management][:subnet]

hdfs_site_values = node[:bcpc][:hadoop][:hdfs][:site_xml]

ruby_block "hdfs_site_generated_values_common" do
  block do
    node.run_state['hdfs_site_generated_values'] =
    {
     'dfs.namenode.name.dir' =>
       node.run_state[:bcpc_hadoop_disks][:mounts]
       .map{ |d| "file:///disk/#{d}/dfs/nn" }.join(','),

     "dfs.ha.namenodes.#{node.chef_environment}" =>
       node[:bcpc][:hadoop][:nn_hosts]
       .map{ |s| "namenode#{s[:node_number]}" }.join(','),

     'dfs.datanode.data.dir' =>
       node.run_state[:bcpc_hadoop_disks][:mounts]
       .map{ |d| "file:///disk/#{d}/dfs/dn" }.join(','),

     'dfs.journalnode.edits.dir' =>
       File.join('/disk', node.run_state[:bcpc_hadoop_disks][:mounts][0].to_s, 'dfs', 'jn'),

     'dfs.client.local.interfaces' =>
       node['bcpc']['floating']['ip'] + '/32'
    }
  end
end

ruby_block "hdfs_site_generated_values_balancer_properties" do
  block do
    # get the speed of the fastest interface and use
    max_concurrent_moves =
      node.run_state[:bcpc_hadoop_disks][:mounts].length *
      node['hadoop']['hdfs']['balancer']['max_concurrent_moves_multiplier']

    default_speed = node['hadoop']['hdfs']['balancer']['bandwidth']
    maximum_nic_speed = Dir.glob('/sys/class/net/*/speed').map do |ff|
      File.read(ff).chomp.to_i rescue 1000
    end.compact.max
    balancer_bandwidth = [default_speed, maximum_nic_speed * 10**6 / 8].max

    balancer_properties = {
     'dfs.datanode.balance.max.concurrent.moves' => max_concurrent_moves,

     'dfs.datanode.balance.bandwidthPerSec' => balancer_bandwidth
    }

    node.run_state['hdfs_site_generated_values'].merge!(balancer_properties)
  end
  only_if { node.run_list.expand(node.chef_environment).recipes
              .include?('bcpc-hadoop::datanode') }
end


ruby_block "hdfs_site_generated_values_nn_properties" do
  block do
    # Using 'map', a hash is built for each host.
    # Using 'reduce', all host hashes are consolidated into a single hash.
    namenode_properties = node[:bcpc][:hadoop][:nn_hosts].map do |host|
      {
       'dfs.namenode.rpc-address.' + node.chef_environment +
         '.namenode' + host[:node_number].to_s =>
         float_host(host[:hostname]) + ':' +
         node[:bcpc][:hadoop][:namenode][:rpc][:port].to_s,

       'dfs.namenode.http-address.' + node.chef_environment +
         '.namenode' + host[:node_number].to_s =>
         float_host(host[:hostname]) + ':' +
         node[:bcpc][:hadoop][:namenode][:http][:port].to_s,

       'dfs.namenode.https-address.' + node.chef_environment +
         '.namenode' + host[:node_number].to_s =>
         float_host(host[:hostname]) + ':' +
         node[:bcpc][:hadoop][:namenode][:https][:port].to_s,
      }
    end.reduce({},:merge)
    node.run_state['hdfs_site_generated_values'].merge!(namenode_properties)
  end
end

ruby_block "hdfs_site_generated_values_krb_properties" do
  block do
    if node[:bcpc][:hadoop][:kerberos][:enable]
      dfs = node[:bcpc][:hadoop][:hdfs][:dfs]

      kerberos_data = node[:bcpc][:hadoop][:kerberos][:data]

      if kerberos_data[:spnego][:princhost] == '_HOST'
        spnego_host = '_HOST'
      else
        spnego_host = kerberos_data[:spnego][:princhost]
      end

      spnego_principal =
        kerberos_data[:spnego][:principal] + '/' + spnego_host + '@' +
        node[:bcpc][:hadoop][:kerberos][:realm]

      spnego_keytab = File.join(node[:bcpc][:hadoop][:kerberos][:keytab][:dir],
                                kerberos_data[:namenode][:spnego_keytab])

      if kerberos_data[:namenode][:princhost] == '_HOST'
        namenode_host = '_HOST'
      else
        namenode_host = kerberos_data[:namenode][:princhost]
      end

      namenode_principal =
        kerberos_data[:namenode][:principal] + '/' + namenode_host + '@' +
        node[:bcpc][:hadoop][:kerberos][:realm]

      namenode_keytab = File.join(node[:bcpc][:hadoop][:kerberos][:keytab][:dir],
                                kerberos_data[:namenode][:keytab])

      if kerberos_data[:datanode][:princhost] == '_HOST'
        dn_host = if node.run_list.expand(node.chef_environment).recipes
                      .include?('bcpc-hadoop::datanode')
                    float_host(node[:fqdn])
                  else
                    kerberos_data[:datanode][:princhost]
                  end
      else
        dn_host = kerberos_data[:datanode][:princhost]
      end

      datanode_principal =
        kerberos_data[:datanode][:principal] + '/' + dn_host + '@' +
        node[:bcpc][:hadoop][:kerberos][:realm]

      datanode_keytab = File.join(node[:bcpc][:hadoop][:kerberos][:keytab][:dir],
                                  kerberos_data[:datanode][:keytab])


      kerberos_properties =
        {
         'dfs.permissions.enabled' => true,

         'dfs.block.access.token.enable' => true,

         'dfs.permissions.superusergroup' =>
           dfs[:permissions][:superusergroup],

         'dfs.web.authentication.kerberos.principal' =>
           spnego_principal,

         'dfs.web.authentication.kerberos.keytab' =>
           spnego_keytab,

         'dfs.namenode.kerberos.principal' =>
           namenode_principal,

         'dfs.namenode.keytab.file' =>
           namenode_keytab,

         'dfs.datanode.kerberos.principal' =>
           datanode_principal,

         'dfs.datanode.keytab.file' =>
           datanode_keytab,

         'dfs.cluster.administrators' =>
           dfs[:cluster][:administrators],

         'dfs.namenode.kerberos.internal.spnego.principal' =>
           '${dfs.web.authentication.kerberos.principal}',

         'dfs.secondary.namenode.kerberos.internal.spnego.principal' =>
           '${dfs.web.authentication.kerberos.principal}',
        }

      if node.run_list.expand(node.chef_environment).recipes
          .include?('bcpc-hadoop::journalnode')

        if kerberos_data[:journalnode][:princhost] == '_HOST'
          jn_host = "_HOST"
        else
          jn_host = kerberos_data[:journalnode][:princhost]
        end

        jn_principal =
          kerberos_data[:journalnode][:principal] + '/' + jn_host + '@' +
          node[:bcpc][:hadoop][:kerberos][:realm]

        jn_keytab = File.join(node[:bcpc][:hadoop][:kerberos][:keytab][:dir],
                              kerberos_data[:journalnode][:keytab])

        jn_properties =
          {
           'dfs.journalnode.keytab.file' =>
             jn_keytab,

           'dfs.journalnode.kerberos.principal' =>
             jn_principal,

           'dfs.journalnode.kerberos.internal.spnego.principal' =>
             spnego_principal
          }
        kerberos_properties.merge!(jn_properties)
      end

      node.run_state['hdfs_site_generated_values'].merge!(kerberos_properties)
    end
  end
end


ruby_block "hdfs_site_generated_values_jn_properties" do
  block do
    if node.run_list.expand(node.chef_environment).recipes
        .include?('bcpc-hadoop::journalnode')
      jn_properties =
        {
         'dfs.journalnode.rpc-address' =>
           node[:bcpc][:floating][:ip] + ':8485',

         'dfs.journalnode.http-address' =>
           node[:bcpc][:floating][:ip] + ':8480',

         'dfs.journalnode.https-address' =>
           node[:bcpc][:floating][:ip] + ':8481',
        }

       node.run_state['hdfs_site_generated_values'].merge!(jn_properties)
    end
  end
end


ruby_block "hdfs_site_generated_values_dn_properties" do
  block do
    if node.run_list.expand(node.chef_environment).recipes
        .include?('bcpc-hadoop::datanode')

      dn_properties =
        {
         'dfs.datanode.address' =>
           node[:bcpc][:floating][:ip] + ':1004',

         'dfs.datanode.http.address' =>
           node[:bcpc][:floating][:ip] + ':1006',
        }

      node.run_state['hdfs_site_generated_values'].merge!(dn_properties)
    end
  end
end

ruby_block "hdfs_site_generated_values_ha_properties" do
  block do
    if node[:bcpc][:hadoop][:hdfs][:HA]
      # This is a cached node search.
      zk_hosts = node[:bcpc][:hadoop][:zookeeper][:servers]

      ha_properties =
        {
         'ha.zookeeper.quorum' =>
           zk_hosts.map{ |s| float_host(s[:hostname]) +
             ":#{node[:bcpc][:hadoop][:zookeeper][:port]}" }.join(','),

         'dfs.namenode.shared.edits.dir' =>
           'qjournal://' +
           zk_hosts.map{ |s| float_host(s[:hostname]) + ":8485" }.join(";") +
           '/' + node.chef_environment,

         # Why is this added twice?
         'dfs.journalnode.edits.dir' =>
           File.join('/disk', node.run_state[:bcpc_hadoop_disks][:mounts][0].to_s, 'dfs', 'jn')
        }
      node.run_state['hdfs_site_generated_values'].merge!(ha_properties)
    end
  end
end

ruby_block "complete_hdfs_site_hash" do
  block do
    node.run_state['complete_hdfs_site_hash'] =
      node.run_state['hdfs_site_generated_values'].merge(hdfs_site_values)
  end
end

template "/etc/hadoop/conf/hdfs-site.xml" do
  source "generic_site.xml.erb"
  mode 0644
  variables ( lazy {
    { :options => node.run_state['complete_hdfs_site_hash'] }
  })
end
