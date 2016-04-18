require "mixlib/shellout"

Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

%w(ldap-utils libsasl2-modules-gssapi-mit).each do |pkg|
  package pkg do
    action :upgrade
  end
end

ruby_block "generate_group_dirs" do
  block do
    initialize_ldap(node[:bcpc][:hadoop][:ldap_query_keytab], "ldap://#{node[:bcpc][:hadoop][:domain]}")
    LDAP_BASE="DC=#{node[:bcpc][:hadoop][:base_dn]}"

    access_groups = []
    roles = []

    # Get all the role accounts from cluster group
    roles.concat(find_object_by_group(LDAP_BASE, :role, "CN=#{node[:bcpc][:hadoop][:acl_group]},#{node[:bcpc][:hadoop][:group_ou]}"))

    # Get all the groups from cluster group
    access_groups = find_object_by_group(LDAP_BASE, :group, "CN=#{node[:bcpc][:hadoop][:acl_group]},#{node[:bcpc][:hadoop][:group_ou]}", 'dn')

    # Loop through each group and push role accounts from each group to role_groups array
    while !access_groups.empty? do
      distName = access_groups.shift
      # Find all the role accounts in the given group
      roles.concat(find_object_by_group(LDAP_BASE, :role, distName))

      # Find all the groups in the given group
      access_groups.concat(find_object_by_group(LDAP_BASE, :group, distName, 'dn'))
    end


    # Build a hash role_groups = {group1: [user1, user2, ...], group2: [...], ...}

    # Get all group DN's roles are in
    role_groups = {}
    while user = roles.pop()
      groups(user).each do |g|
        role_groups[g] = []
      end
    end

    # For each group get a list of all user and role accounts in the group
    role_groups.keys.each do |g|
      begin
        role_groups[g] = role_groups[g].concat(getent(:group, g)['members'])
      rescue KeyError
        # remove groups which are not found
        # (e.g. race conditions and groups which do not resolve to a name)
        role_groups.delete(g)
      end
    end

    require 'thread'
    group_queue = Queue.new()
    # create a directory if the group has more than one user and matches group naming rules
    role_groups.each_pair{|g, users| group_queue.push(g) if filter_nonproject_groups(g, users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])}
    threads = (0..node[:bcpc][:hadoop][:dir_threads]).map do
      Thread.new do
        begin
          while group = group_queue.pop(true)
            # Chef::Log does not seem to work in RubyBlocks and may not be thread safe
            # puts will step on itself but splat to the screen if in debug mode
            puts "Group: #{group}" if Chef::Config[:log_level] == :debug
            new_dir_creation(node[:bcpc][:hadoop][:hdfs_url], "/groups/#{group}", "hdfs:#{group}", node[:bcpc][:hadoop][:hadoop][:group_dir_mode], node.run_context)
          end
        rescue ThreadError => e
        end
      end
    end
    threads.map(&:join)
  end
  action :run
end
