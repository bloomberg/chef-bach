#
# Cookbook Name:: kafka-bcpc
# Recipe:: coordinate
# Function:: Recipe to start/restart Kafka service
#
if node["bcpc"]["kafka"]["skip_restart_coordination"]
  Chef::Log.info "Coordination of Kafka restart will be skipped as per user request."
  
  ruby_block 'coordinate-kafka-start' do
    block do
      Chef::Log.debug 'bcpc recipe to coordinate Kafka start is used'
    end
    action :nothing
    notifies :restart, 'service[kafka]', :delayed
  end

  service 'kafka' do
    provider kafka_init_opts[:provider]
    supports start: true, stop: true, restart: true, status: true
    action kafka_service_actions
  end
  
else

  ruby_block 'coordinate-kafka-start' do
    block do
      Chef::Log.debug 'bcpc recipe to coordinate Kafka start is used'
    end
    action :nothing
  end

  #
  # When there is a need to restart kafka service, a lock need to be taken so that the restart is sequenced preventing all nodes being down at the sametime
  # If there is a failure in acquiring a lock with in a certian period, the restart is scheduled for the next run on chef-client on the node.
  # To determine whether the prev restart failed is the node attribute node[:bcpc][:kafka][:restart_failed] is set to true
  # This ruby block is to check whether this node attribute is set to true and if it is set then gets the kafka service restart process in motion.
  #
  ruby_block "handle_prev_kafka_restart_failure" do
    block do
      Chef::Log.info "Need to restart kafka since it failed during the previous run. Another node's restart process failure is a possible reason"
    end
    action :create
    only_if { node[:bcpc][:kafka][:restart_failed] and 
            !process_restarted_after_failure?(node[:bcpc][:kafka][:restart_failed_time],"kafka.Kafka")}
  end

  #
  # Since string with all the zookeeper nodes is used multiple times this variable is populated once and reused reducing calls to Chef server
  #
  zk_hosts = (node[:bcpc][:hadoop][:zookeeper][:servers].map{|zkhost| "#{zkhost['hostname']}:#{node[:bcpc][:hadoop][:zookeeper][:port]}"}).join(",")
  
  #
  # znode is used as the locking mechnism to control restart of services. The following code is to build the path
  # to create the znode before initiating the restart of Kafka service 
  #
  lock_znode_path = format_restart_lock_path(node[:bcpc][:hadoop][:restart_lock][:root],"kafka")

  #
  # All kafka service restart situations like changes in config files or restart due to previous failures invokes this ruby_block
  # This ruby block tries to acquire a lock and if not able to acquire the lock, sets the restart_failed node attribute to true
  #
  ruby_block "acquire_lock_to_restart_kafka" do
    require 'time'
    block do
      tries = 0
      Chef::Log.info("#{node[:hostname]}: Acquring lock at #{lock_znode_path}")
      while true 
        lock = acquire_restart_lock(lock_znode_path, zk_hosts, node[:fqdn])
        if lock
          break
        else
          tries += 1
          if tries >= node[:bcpc][:hadoop][:restart_lock_acquire][:max_tries]
            failure_time = Time.now().to_s
            Chef::Log.info("Couldn't acquire lock to restart Kafka with in the #{node[:bcpc][:hadoop][:restart_lock_acquire][:max_tries] * node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time]} secs. Failure time is #{failure_time}")
            Chef::Log.info("Node #{get_restart_lock_holder(lock_znode_path, zk_hosts)} may have died during Kafka restart.")
            node.set[:bcpc][:hadoop][:kafka][:restart_failed] = true
            node.set[:bcpc][:hadoop][:kafka][:restart_failed_time] = failure_time
            node.save
            break
          end
          sleep(node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time])
        end
      end
    end
    action :nothing
    subscribes :create, "ruby_block[coordinate-kafka-start]", :immediate
    subscribes :create, "ruby_block[handle_prev_kafka_restart_failure]", :immediate
  end
  
  #
  # If lock to restart kafka service is acquired by the node, this ruby_block executes which is primarily used to notify kafka service to restart
  #
  ruby_block "coordinate_kafka_restart" do
    block do
      Chef::Log.info("Kafka will be restarted in node #{node[:fqdn]}")
    end
    action :create
    only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
    notifies :restart, 'service[kafka]', :immediate
  end

  service 'kafka' do
    provider kafka_init_opts[:provider]
    supports start: true, stop: true, restart: true, status: true
    action kafka_service_actions
  end
  
  #
  # Once the Kafka service restart is complete, the following block releases the lock if the node executing is the one which holds the lock 
  #
  ruby_block "release_kafka_restart_lock" do
    block do
      Chef::Log.info("#{node[:hostname]}: Releasing lock at #{lock_znode_path}")
      lock_rel = rel_restart_lock(lock_znode_path, zk_hosts, node[:fqdn])
      if lock_rel
        node.set[:bcpc][:kafka][:restart_failed] = false
        node.save
      end
    end
    action :create
    only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
  end
end
