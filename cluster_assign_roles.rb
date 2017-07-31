#!/usr/bin/env ruby
#
# Script to assign roles to cluster nodes based on a definition in cluster.txt.
#
# Usage:
#   ./cluster_assign_roles.rb environment install_type (hostname)
#
# - Machines will be configured to use the environment provided.
#
# - An install_type is needed; options are Hadoop, Kafka, or Basic
#
# - If no hostname is provided, all nodes will be attempted
#
# - if a nodename is provided, either by hostname or ip address, only
#   that node will be attempted
#
# - if a chef object is provided, e.g. role[ROLE-NAME] or
#   recipe[RECIPE-NAME], only nodes marked for that action are attempted
#

require 'json'
require 'mixlib/shellout'
require 'net/ssh'
require 'parallel'
require 'pry'
require 'uri'
require_relative 'lib/cluster_data'

class ClusterAssignRoles
  include BACH::ClusterData

  #
  # Takes no arguments.
  #
  # Returns a list of cluster.txt entries for head nodes.
  #
  def all_hadoop_head_nodes
    # All head nodes should have this specific role.
    confirmed_head_nodes = parse_cluster_txt.select do |nn|
      nn[:runlist].include?('role[BCPC-Hadoop-Head]')
    end

    # Any nodes that have something matching "Head"
    possible_head_nodes = parse_cluster_txt.select do |nn|
      nn[:runlist].include?('Head')
    end

    #
    # Nodes with runlists matching "Head," but no BCPC-Hadoop-Head,
    # are a potentially dangerous circumstance.  Abort run if found!
    #
    nodes_with_incomplete_runlist =
      possible_head_nodes - confirmed_head_nodes

    if nodes_with_incomplete_runlist.any? && confirmed_head_nodes.any?
      raise "Aborting cluster assign roles. " \
        "Found potential head nodes lacking role[BCPC-Hadoop-Head]: " +
        nodes_with_incomplete_runlist.map { |nn| nn[:hostname] || 'null' }.join
    end

    confirmed_head_nodes
  end

  # If no runlist is provided, the runlist in cluster.txt will be used.
  # arguments:
  #   nodes   -  a list of node objects (e.g. from parse_cluster_txt())
  #   runlist -- a string for a Chef run_list
  # returns:
  #   nothing
  # side-affect:
  #   updates Chef-server with runlists for nodes passed in
  def assign_roles(nodes:, runlist: nil)
    nodes.each do |node|
      chef_node_object = ridley.node.find(node[:fqdn])

      if chef_node_object.nil?
        raise "Could not find node object for #{node[:fqdn]}"
      end

      target_runlist = if runlist.nil?
        node[:runlist].split(',')
      elsif runlist.is_a?(String)
        runlist.split(',')
      else
        raise "No runlist for node #{node[:fqdn]}"
      end

      chef_node_object.run_list = target_runlist
      chef_node_object.save
    end

    puts 'Assigned roles for ' + nodes.map{|nn| nn[:hostname]}.join(', ')
  end

  #
  # Block until provided 'nodes' turn up in results of 'search'
  #
  # If nodes are not found, raises an exception after 'timeout' seconds.
  #
  def wait_for_indexed_roles(nodes:, search:, timeout: 180)
    fqdn_list = nodes.map do |nn|
      nn[:fqdn]
    end

    timeout.times do |ii|
      found_nodes = ridley.search(:node, search).map do |nn|
        nn.name.downcase
      end.to_set

      if found_nodes.superset?(fqdn_list.to_set)
        puts "Found index entries for #{found_nodes.length} nodes"
        break
      else
        if ii % 60 == 0
          if ii == 0
            reindex_chef_server
          end
          puts "Waiting for nodes to appear in search results (#{search})..."
        elsif ii == (timeout - 1)
          raise "Did not find indexed roles for #{fqdn_list} " \
                "after #{timeout} secs!"
        end
        sleep 1
      end
    end
  end

  #
  # Run chef on a node (cluster.txt entry) with a given
  # runlist (string or array)
  #
  # This method assumes the node already has chef installed with a
  # valid configuration.
  #
  # Calling with override: true will cause chef-client to use -o
  # instead of -r, so the node's saved runlist is left intact.
  #
  def chef_node_with_runlist(node:, runlist:, override: false)
    if runlist.is_a?(Array)
      runlist = runlist.join(',')
    end

    #
    # chef-bach recipes often expect to create data bags on the
    # server, so clients are granted admin permission during chef
    # runs.
    #
    set_chef_admin(node: node, admin: true)

    runlist_switch = override ? '-o' : '-r'
    chef_command = "sudo chef-client #{runlist_switch} #{runlist}"

    result = ssh(host: node[:ip_address],
                 username: 'ubuntu',
                 password: cobbler_root_password,
                 command: chef_command,
                 streaming: true)

    #
    # Clients are de-admined after the chef run because subsequent
    # runs will no longer require admin perms.
    #
    set_chef_admin(node: node, admin: false)

    if result[:status] == 0
      puts "#{node[:fqdn]}: Got status #{result[:status]} from chef run"
    else
      raise "#{node[:fqdn]}: Got failed status #{result[:status]} " \
            'from chef run!'
    end
  end

  def install_basic(target_nodes)
    target_nodes.each do |node|
      unless ridley.node.find(node[:fqdn]) && ridley.client.find(node[:fqdn])
        install_stub(node: node)
      end

      #
      # After installing chef-vault in install_stub, we need to
      # re-index node data and re-run chef searches on all our vaults.
      #
      refresh_vault_keys(node)

      runlist = 'role[Basic],recipe[bcpc::default],recipe[bcpc::networking]'
      puts "#{node[:fqdn]}: Cheffing with runlist '#{runlist}'"
      chef_node_with_runlist(node: node, runlist: runlist)
    end
  end

  #
  # The Hadoop convergence order is complex.
  #
  # 1. All nodes are converged on "Role[Basic]"
  # 2. Head nodes converged on "Role[BCPC-Hadoop-Head]"
  # 3. Head nodes converged with complete runlists.
  # 4. All workers converged with complete run lists.
  #
  # "install_bootstrap" handles step #2, cheffing the head nodes with
  # a partial runlist.  The method name comes from the old C-A-R.sh.
  #
  def install_bootstrap(target_nodes)
    # Head nodes must be installed before workers.
    target_head_nodes = target_nodes & all_hadoop_head_nodes

    partial_runlist = 'role[BCPC-Hadoop-Head]'

    # See comments in install_hadoop
    assign_roles(nodes: all_hadoop_head_nodes, runlist: partial_runlist)

    wait_for_indexed_roles(nodes: all_hadoop_head_nodes,
                           search: 'role:BCPC-Hadoop-Head')

    target_head_nodes.each do |node|
      puts "#{node[:fqdn]}: Cheffing head node with partial runlist"
      chef_node_with_runlist(node: node, runlist: partial_runlist)
    end
  end

  def install_hadoop(target_nodes)
    # Head nodes must be installed before workers.
    target_head_nodes = target_nodes & all_hadoop_head_nodes
    target_worker_nodes = target_nodes - all_hadoop_head_nodes

    #
    # Many bcpc recipes expect to be able to search for nodes based on
    # their configured roles.  This means we have to pre-populate the
    # roles before we can chef any individual head node.
    #
    # 'assign_roles' will update the node objects with their full run
    # list.  After that, we wait for the new nodes to appear in the
    # results of a Chef search.
    #
    assign_roles(nodes: all_hadoop_head_nodes)

    wait_for_indexed_roles(nodes: all_hadoop_head_nodes,
                           search: 'role:BCPC-Hadoop-Head*')

    target_head_nodes.each do |node|
      puts "#{node[:fqdn]}: Cheffing head node with full runlist"
      chef_node_with_runlist(node: node, runlist: node[:runlist])
    end

    target_worker_nodes.each do |node|
      puts "#{node[:fqdn]}: Cheffing worker node with full runlist"
      chef_node_with_runlist(node: node, runlist: node[:runlist])
    end
  end

  def install_kafka(target_nodes)
    # Zookeeper has to come up before Kafka.
    all_zk_nodes = parse_cluster_txt.select do |node|
      node[:runlist].include?('role[BCPC-Kafka-Head-Zookeeper]')
    end

    target_zk_nodes = target_nodes & all_zk_nodes
    target_kafka_nodes = target_nodes - all_zk_nodes

    # See comments in the install_hadoop method.
    assign_roles(nodes: all_zk_nodes)
    wait_for_indexed_roles(nodes: all_zk_nodes,
                           search: 'role:BCPC-Kafka-Head-Zookeeper')

    target_zk_nodes.each do |node|
      puts "#{node[:fqdn]}: Cheffing Zookeeper node with full runlist"
      chef_node_with_runlist(node: node, runlist: node[:runlist])
    end

    target_kafka_nodes.each do |node|
      puts "#{node[:fqdn]}: Cheffing Kafka node with full runlist"
      chef_node_with_runlist(node: node, runlist: node[:runlist])
    end
  end

  #
  #
  # install_stub uses knife bootstrap to configure chef-client,
  # chef-vault, and SSH on a new node.
  #
  # The bootstrap process does not verify SSH keys, but if persistent
  # host keys are saved on the server, they will replace the
  # un-trusted ones generated by the install script.
  #
  # It takes a cluster.txt entry and an optional runlist as arguments.
  #
  # Calling install_stub on an already-installed node may upgrade chef
  # and re-set its runlist, but is otherwise harmless.
  #
  def install_stub(node:, runlist: 'recipe[bcpc::ssh]')
    puts "#{node[:fqdn]}: Installing and configuring chef"

    bootstrap_url =
      'http://' +
      chef_environment[:override_attributes][:bcpc][:bootstrap][:server] +
      '/chef-install.sh'

    require 'pry'

    #
    # 'knife bootstrap' can't handle periods in data bag item names
    # when provided on the command line.
    #
    # The simple workaround is to provide the names in JSON format instead.
    #
    vault_json = if ridley.data_bag.find("ssh_host_keys/#{node[:fqdn]}")
                   {ssh_host_keys: node[:fqdn]}.to_json.to_s
                 else
                   '{}'
                 end

    cc =
      Mixlib::ShellOut.new('sudo', '/opt/chefdk/bin/knife', 'bootstrap',
                           '-y',
                           '-E', chef_environment_name,
                           '-r', runlist,
                           '-x', 'ubuntu',
                           '-P', cobbler_root_password,
                           '--bootstrap-wget-options', '-e use_proxy=no',
                           '--bootstrap-url', bootstrap_url,
                           '--sudo',
                           '--use-sudo-password',
                           '--node-ssl-verify-mode', 'none',
                           '--no-node-verify-api-cert',
                           '--no-host-key-verify',
                           '-N', node[:fqdn],
                           '--bootstrap-vault-json', vault_json,
                           node[:ip_address])
    cc.run_command

    if cc.status.success?
      puts "#{node[:fqdn]}: Chef install successful"
    else
      puts cc.stdout
      $stderr.puts cc.stderr
      cc.error!
    end

    cc.status
  end

  def install_stubs(target_nodes)
    target_nodes.each do |target_node|
      install_stub(node: target_node)
    end
  end

  def set_chef_admin(node:, admin:)
    client = ridley.client.find(node[:fqdn])

    if client.nil?
      raise "Could not find client object for '#{node[:fqdn]}'"
    end

    client.admin = admin
    client.save
  end

  #
  # Invokes ruby-native net/ssh to run commands on a remote host.
  # This method explicitly allocates a pty for ssh, then listens for,
  # and responds to, sudo password prompts.
  #
  # Arguments:
  # - host, string, hostname to ssh into
  # - username, string, username to use for ssh
  # - password, string, password to use for ssh
  # - command, string, command to run remotely
  # - streaming, boolean, when true, print command output to terminal
  #
  # Return values:
  # - A hash with keys for status, stdout, and stderr.
  #
  def ssh(host:, username:, password:, command:, streaming: false)
    Net::SSH.start( host, username, :password => password) do |session|
      stdout = ''
      stderr = ''
      exit_status = nil

      session.open_channel do |channel|
        channel.request_pty do |_c, success|
          if command.include?('sudo') && !success
            raise 'Failed to request pty for ssh, sudo will fail.'
          end

          channel.exec(command) do|_c,exec_success|
            unless exec_success
              raise "Failed to invoke '#{command}' on #{host}!"
            end

            channel.on_data do |_c,data|
              if data =~ /^\[sudo\] password for #{username}:/
                channel.send_data(password + "\n")
              end

              stdout << data
              $stdout.print(data) if streaming
            end

            channel.on_extended_data do |_c,data|
              stderr << data
              $stderr.print(data) if streaming
            end

            channel.on_request('exit-status') do |_c,data|
              # Working around buggy #read_long method.
              if(data.available == 4)
                exit_status = data.read(4).unpack('N').first
              else
                $stderr.puts "Found #{data.available} bytes in exit-status " \
                             "buffer, expected to find exactly 4!\n" \
                             "buffer: #{data.inspect}"
                exit_status = -1
              end
            end
          end
        end
      end
      session.loop
      {stdout: stdout, stderr: stderr, status: exit_status}
    end
  end

  def car_cli
    requested_environment = ARGV[0]
    install_type = ARGV[1].to_s.downcase
    optional_thing = ARGV[2]

    if requested_environment.nil? || install_type.nil?
      $stderr.puts "Usage : #{__FILE__} environment install_type (hostname)\n"
      exit 1
    end

    unless ridley.environment.find(requested_environment)
      raise "'#{requested_environment}' not found on Chef server!"
    end

    unless %w{stubs basic bootstrap hadoop kafka}.include?(install_type)
      raise "Install type must be one of stubs, basic, bootstrap, hadoop, kafka. " \
            "You provided '#{install_type}'."
    end

    target_nodes = if optional_thing.nil?
                     parse_cluster_txt
                   else
                     node_matches = parse_cluster_txt.select do |entry|
                       entry[:ip_address].include?(optional_thing) ||
                       entry[:fqdn].include?(optional_thing.downcase)
                     end

                     if node_matches.empty?
                       node_matches = parse_cluster_txt.select do |entry|
                         entry[:runlist]
                           .downcase
                           .include?(optional_thing.downcase)
                       end
                     end

                     node_matches
                   end

    # Nodes with a runlist matching "SKIP" will never be valid targets.
    target_nodes.reject! do |entry|
      entry[:runlist].include?('SKIP')
    end

    # If an optional_thing was specified, print the search results.
    unless optional_thing.nil?
      hostnames = if target_nodes.empty?
                    '(nothing)'
                  else
                    target_nodes.map { |ee| ee[:hostname] }.join("\n  ")
                  end

      puts "Search '#{optional_thing}' matched:\n  #{hostnames}"
    end

    if target_nodes.any?
      send("install_#{install_type}".to_sym, target_nodes)
    else
      $stderr.puts "No target nodes found matching '#{optional_thing.to_s}'"
      exit 1
    end
  end
end

ClusterAssignRoles.new.car_cli
