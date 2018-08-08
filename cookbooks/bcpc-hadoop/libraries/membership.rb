# membership.rb
# Routines for querying cluster and group membership

module Bcpc_Hadoop::Helper
  require 'set'

  # Fetch the valid members with cluster access
  # Return a tuple of [[users], [role_accounts]]
  def cluster_members
    ldap = Bcpc_Hadoop::Helper::LDAPSearch.new({
      host: node['bcpc']['hadoop']['ldap']['domain'],
      port: node['bcpc']['hadoop']['ldap']['port'],
      base_dn: node['bcpc']['hadoop']['ldap']['base_dn'],
      roles_dn: node['bcpc']['hadoop']['ldap']['roles_dn'],

      # LDAP Simple Authentication
      user: node['bcpc']['hadoop']['hdfs']['ldap']['user'],
      password: node['bcpc']['hadoop']['hdfs']['ldap']['password'] ||
        get_config('password', 'ldap', 'os'),
    })

    # Users, Roles, and Groups with cluster access
    cluster_acl = node['bcpc']['hadoop']['ldap']['cluster_acl']
    users, roles, groups = Set.new, Set.new, [cluster_acl]

    # Start the search from the cluster_acl group
    # Breadth First Search for users in the Group membership graph
    # Recurse down the group membership graph
    # Add all the 'group' member neighbors to the queue
    while group = groups.shift
      users.merge(ldap.group_search(:user, group))
      roles.merge(ldap.group_search(:role, group))
      groups.concat(ldap.group_search(:group, group, 'dn'))
    end

    return [users.to_a, roles.to_a]
  end

  def cluster_users
    users, roles = cluster_members
    return users
  end

  def cluster_roles
    users, roles = cluster_members
    return roles
  end

  # Build a hash of role_groups = {group1: [user1, user2, ...], group2: [...], ...}
  # For each group get a list of all user and role accounts in the group
  # Ignore the invalid cluster groups and groups that don't resolve
  def cluster_groups
    cluster_roles.reduce(Set.new) do |role_groups, role|
      role_groups.merge(groups(role))
    end.select do |group|
      begin
        members = getent(:group, group)['members']
        cluster_group?(group, members)
      rescue
        false
      end
    end
  end

  # A valid cluster group for dir_creation:
  #   is not a prohibited group
  #   has at least two users
  #   succeeds at name resolution (we can get the GID)
  def cluster_group?(group, users)
    prohibited_groups = [
      /^users$/,
      /^roleacct$/,
      /^prqspw_roles$/,
      /^db2*/,
      /^git*/,
      /^svn*/,
      /^dba(?:dmin)?$/,
      /^u_ou_acl_sys_rabbitmq_admin_grp$/
    ]

    prohibited =
      prohibited_groups.any? do |regex|
        Regexp.new(regex).match(group)
      end

    return (
      (!prohibited) &&
      (users.length >= 2) &&
      (group.to_i.to_s != group)
    )
  end
end
