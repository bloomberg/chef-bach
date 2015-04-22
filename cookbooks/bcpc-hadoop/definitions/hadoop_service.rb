define :hadoop_service, :service_name => nil, :dependencies => nil, :process_identifier => nil do

  params[:service_name] ||= params[:name]

  service "#{params[:service_name]}" do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
  end

  if node["bcpc"]["hadoop"]["skip_restart_coordination"]
    Chef::Log.info "Coordination of #{params[:service_name]} restart will be skipped as per user request."
    begin
      res = resources(service: "#{params[:service_name]}")
      if params[:dependencies]
        params[:dependencies].each do |dep|
          res.subscribes(:restart, "#{dep}", :delayed)
        end
      end
    rescue Chef::Exceptions::ResourceNotFound
      Chef::Log.info("Resource service #{params[:service_name]} not found")
    end
  else
    if !params[:process_identifier]
      Chef::Application.fatal!("hadoop_service for #{params[:service_name]} need to specify a valid value for the parameter :process_identifier")
    end
    #
    # When there is a need to restart a hadoop service, a lock need to be taken so that the restart is sequenced preventing all nodes being down at the sametime
    # If there is a failure in acquiring a lock with in a certian period, the restart is scheduled for the next run on chef-client on the node.
    # To determine whether the prev restart failed is the node attribute node[:bcpc][:hadoop][:service_name][:restart_failed] is set to true
    # This ruby block is to check whether this node attribute is set to true and if it is set then gets the hadoop service restart process in motion.
    #
    ruby_block "handle_prev_#{params[:service_name].gsub('-','_')}_restart_failure" do
      block do
        Chef::Log.info "Need to restart #{params[:service_name]} since it failed during the previous run. Another node's restart process failure is a possible reason"
      end
      action :create
      only_if { node[:bcpc][:hadoop][params[:service_name].gsub('-','_').to_sym][:restart_failed] and 
              !process_restarted_after_failure?(node[:bcpc][:hadoop][params[:service_name].gsub('-','_').to_sym][:restart_failed_time],"#{params[:process_identifier]}")}
    end
    #
    # Since string with all the zookeeper nodes is used multiple times this variable is populated once and reused reducing calls to Chef server
    #
    zk_hosts = (get_node_attributes(MGMT_IP_ATTR_SRCH_KEYS,"zookeeper_server","bcpc-hadoop").map{|zkhost| "#{zkhost['mgmt_ip']}:#{node[:bcpc][:hadoop][:zookeeper][:port]}"}).join(",")
    #
    # znode is used as the locking mechnism to control restart of services. The following code is to build the path
    # to create the znode before initiating the restart of hadoop service 
    #
    lock_znode_path = format_restart_lock_path(node[:bcpc][:hadoop][:restart_lock][:root],"#{params[:service_name]}")
    #
    # All hadoop service restart situations like changes in config files or restart due to previous failures invokes this ruby_block
    # This ruby block tries to acquire a lock and if not able to acquire the lock, sets the restart_failed node attribute to true
    #
    ruby_block "acquire_lock_to_restart_#{params[:service_name].gsub('-','_')}" do
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
              Chef::Log.info("Couldn't acquire lock to restart #{params[:service_name]} with in the #{node[:bcpc][:hadoop][:restart_lock_acquire][:max_tries] * node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time]} secs. Failure time is #{failure_time}")
              Chef::Log.info("Node #{get_restart_lock_holder(lock_znode_path, zk_hosts)} may have died during #{params[:service_name]} restart.")
              node.set[:bcpc][:hadoop][params[:service_name].gsub('-','_').to_sym][:restart_failed] = true
              node.set[:bcpc][:hadoop][params[:service_name].gsub('-','_').to_sym][:restart_failed_time] = failure_time
              node.save
              break
            end
            sleep(node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time])
          end
        end
      end
      action :nothing
      if params[:dependencies]
        params[:dependencies].each do |dep|
          subscribes :create, "#{dep}", :immediate
        end
      end
      subscribes :create, "ruby_block[handle_prev_#{params[:service_name].gsub('-','_')}_restart_failure]", :immediate
    end
    #
    # If lock to restart hadoop service is acquired by the node, this ruby_block executes which is primarily used to notify the hadoop service to restart
    #
    ruby_block "coordinate_#{params[:service_name].gsub('-','_')}_restart" do
      block do
        Chef::Log.info("Data node will be restarted in node #{node[:fqdn]}")
      end
      action :create
      only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
    end

    begin
      res = resources(service: "#{params[:service_name]}")
      res.subscribes(:restart, "ruby_block[coordinate_#{params[:service_name].gsub('-','_')}_restart]", :immediate)
    rescue Chef::Exceptions::ResourceNotFound
      Chef::Log.info("Resource service #{params[:service_name]} not found")
    end
    #
    # Once the hadoop service restart is complete, the following block releases the lock if the node executing is the one which holds the lock 
    #
    ruby_block "release_#{params[:service_name].gsub('-','_')}_restart_lock" do
      block do
        Chef::Log.info("#{node[:hostname]}: Releasing lock at #{lock_znode_path}")
        lock_rel = rel_restart_lock(lock_znode_path, zk_hosts, node[:fqdn])
        if lock_rel
          node.set[:bcpc][:hadoop][params[:service_name].gsub('-','_').to_sym][:restart_failed] = false
          node.save
        end
      end
      action :create
      only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
    end
  end
end
