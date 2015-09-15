include_recipe 'bach_cluster::settings'

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

# Converge nodes with basic roles so they are available in node search.
1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}"
  vm_mgmt_ip = "10.0.101." + (3 + n).to_s

  bach_cluster_node vm_name do
    cpus 1
    memory 3072
    management_ip vm_mgmt_ip
    management_netmask '255.255.255.240'
    run_list [
              'recipe[bach_common::apt_proxy]',
              'recipe[bach_common::binary_server]',
              'role[Basic]', 
             ]
    #complete true # Completely overwrite the runlist.
  end
end

# Force the chef server to rebuild its solr index.
# (Index rebuild via knife is no longer supported.)
machine_execute 'chef-server-reindex' do
  machine bootstrap_fqdn
  chef_server chef_server_config_hash
  command "chef-server-ctl reindex " +
    node[:bach][:cluster][:organization][:name]
end

ruby_block "wait-for-reindex" do
  block do
    #
    # We're calling out to knife instead of using the Chef API because
    # I couldn't figure out how to call Cheffish by hand from a ruby
    # block.
    #
    # This is definitely the wrong way to do this.
    #
    # We created a .chef/knife.rb when we set up the bootstrap server,
    # so knife is already configured.
    #
    def find_client(string)
      command_string = 
        'env -u http_proxy -u https_proxy -u no_proxy ' +
        ' -u HTTP_PROXY -u HTTPS_PROXY -u NO_PROXY ' +
        "knife search client '#{string}' " +
        '2>&1 >/dev/null | grep -v 0 | grep found'

      Chef::Log.debug("Running: #{command_string}")

      cmd = Mixlib::ShellOut.new(command_string,
                                 :cwd => Chef::Config[:chef_repo_path])
      r = cmd.run_command
      Chef::Log.debug("Result: #{r.inspect}")
      !cmd.error?
    end
    search_string = "name:bach-vm1-b#{build_id}*"
    until(find_client(search_string))
      Chef::Log.info("Waiting for #{search_string} to appear in index")
      sleep 10
    end
    search_string = "name:bach-vm2-b#{build_id}*"
    until(find_client(search_string))
      Chef::Log.info("Waiting for #{search_string} to appear in index")
      sleep 10
    end
  end
end

3.times do
  # Re-converge the first head node with added runlist items.
  bach_cluster_node "bach-vm1-b#{build_id}" do
    cpus 1
    memory 3072
    management_ip "10.0.101." + (3 + 1).to_s
    management_netmask '255.255.255.240'
    run_list [
              'role[BCPC-Hadoop-Head-Namenode-NoHA]',
              'role[BCPC-Hadoop-Head-HBase]',
              #'role[Copylog]',
             ]
  end

  # Re-converge the second head node with added runlist items.
  bach_cluster_node "bach-vm2-b#{build_id}" do
    cpus 1
    memory 3072
    management_ip "10.0.101." + (3 + 2).to_s
    management_netmask '255.255.255.240'
    run_list [
              'role[BCPC-Hadoop-Head-Namenode-Standby]',
              'role[BCPC-Hadoop-Head-MapReduce]',
              'role[BCPC-Hadoop-Head-Hive]',
              #'role[Copylog]',
             ]
  end

  # Skip 1 and 2, they are our head nodes.
  # Reconverge workers with the complete runlist.
  3.upto(total_node_count).each do |n|
    vm_name = "bach-vm#{n}-b#{build_id}" # XXX: replace with helper!
    bach_cluster_node vm_name do
      cpus 1
      memory 3072
      management_ip "10.0.101." + (3 + n).to_s
      management_netmask '255.255.255.240'
      run_list [
                'role[BCPC-Hadoop-Worker]' # XXX: replace with helper!
                #'role[Copylog]',
               ]
    end
  end
end
