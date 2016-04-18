require "mixlib/shellout"

Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

%w(ldap-utils libsasl2-modules-gssapi-mit).each do |pkg|
  package pkg do
    action :upgrade
  end
end

ruby_block "generate_user_dirs" do
  block do
    initialize_ldap(node[:bcpc][:hadoop][:ldap_query_keytab], "ldap://#{node[:bcpc][:hadoop][:domain]}")
    LDAP_BASE="DC=#{node[:bcpc][:hadoop][:base_dn]}"

    group_list = []
    users_list = []

    # Get all the users from cluster group
    users_list.concat(find_object_by_group(LDAP_BASE, :user, "CN=#{node[:bcpc][:hadoop][:acl_group]},#{node[:bcpc][:hadoop][:group_ou]}"))
    users_list.concat(find_object_by_group(LDAP_BASE, :role, "CN=#{node[:bcpc][:hadoop][:acl_group]},#{node[:bcpc][:hadoop][:group_ou]}"))

    # Get all the groups from cluster group
    group_list = find_object_by_group(LDAP_BASE, :group, "CN=#{node[:bcpc][:hadoop][:acl_group]},#{node[:bcpc][:hadoop][:group_ou]}", 'dn')

    # Loop through each group and push users from each group to users_list array
    while !group_list.empty? do
      distName = group_list.shift
      # Find all the users in the given group
      users_list.concat(find_object_by_group(LDAP_BASE, :user, distName))
      users_list.concat(find_object_by_group(LDAP_BASE, :role, distName))

      # Find all the groups in the given group
      group_list.concat(find_object_by_group(LDAP_BASE, :group, distName, 'dn'))
    end

    require 'thread'
    queue = Queue.new
    users_list.each{|u| queue.push(u)}
    threads = (0..node[:bcpc][:hadoop][:dir_threads]).map do
      Thread.new do
        begin
          while user = queue.pop(true)
            # Chef::Log does not seem to work in RubyBlocks and may not be thread safe
            # puts will step on itself but splat to the screen if in debug mode
            puts("User: #{user}") if Chef::Config[:log_level] == :debug
            new_dir_creation(node[:bcpc][:hadoop][:hdfs_url], "/user/#{user}", user, node[:bcpc][:hadoop][:hadoop][:user_dir_mode], node.run_context)
          end
        rescue ThreadError => e
        end
      end
    end
    threads.map(&:join)
  end
  action :run
end
