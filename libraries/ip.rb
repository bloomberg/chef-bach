module BachCluster
  module IP
    #
    # It would be great if these methods could read from DNS and fall
    # back to the environment file.
    #
    def get_networks(build_id:,
                     netblock:)
      if netblock.prefix > 26
        raise RangeError 'Configured netblock must be no smaller than a /26!'
      end

      all_networks = netblock.subnet(26)
      environment_count = all_networks.count
      my_network = all_networks[build_id.to_i % environment_count]

      # Split the /26 into 4x /28s, return just three of them. 
      # The fourth is unused.
      return my_network.subnet(28)[0..2]
    end

    def get_ip_hash(build_id:,
                    node_count:, 
                    networks:)

      if node_count > 13
        raise RangeError "We've hardcoded /28 networks, so node_count must " +
          "be <= 13. (Because the hypervisor consumes one IP on each net)"
      end

      # Add keys with empty arrays for the hypervisor and bootstrap vm
      bootstrap_name = "bach-vm-bootstrap-b#{build_id}"
      hash = { bootstrap_name => [],
              'hypervisor' => [] }

      # Add keys with empty arrays for all the nodes.
      # (We're reducing an array of hashes into one hash.)
      hash = node_count.times.collect do |n|
        {"bach-vm#{n}-b#{build_id}" => [] }
      end.reduce(hash, :merge)
      
      networks.map do |ip|
        hash['hypervisor'] << ip.hosts[0].to_string
        hash[bootstrap_name] << ip.hosts[1].to_string
        node_count.times do |n|
          hash["bach-vm#{n}-b#{build_id}"] << ip.hosts[n+1].to_string
        end
      end

      return hash
    end
  end
end

[ 
 Chef::Recipe,
 Chef::Resource
].each do |klass| 
  klass.send(:include, BachCluster::IP)
end
