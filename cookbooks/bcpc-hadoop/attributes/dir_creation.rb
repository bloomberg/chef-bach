# Directory Creation Attributes
# Attributes for configuring the various dir creation recipes

# HDFS User Directory Configuration
# Directory Owner is always the name of the dirinfo entry
default['bcpc']['hadoop']['dir_creation']['user'].tap do |user|
  # default entry values
  user['defaults'] = {
    group: 'hdfs',
    perms: '0700',
    space_quota: '30G',
    ns_quota: 'NO_QUOTA'
  }

  user['dirinfo'] = {
    ## Example dirinfo entry:
    # user_dirname: {
    #   group: 'group',
    #   perms: '0700',
    #   space_quota: '5T',
    #   ns_quota: '500000'
    # }
  }
end

# HDFS Groups Directory Configuration
# Directory Group is always the name of the dirinfo entry
default['bcpc']['hadoop']['dir_creation']['groups'].tap do |groups|
  # default entry values
  groups['defaults'] = {
    owner: 'hdfs',
    perms: '0770',
    space_quota: '50G',
    ns_quota: 'NO_QUOTA'
  }

  groups['dirinfo'] = {
    ## Example dirinfo entry:
    # group: {
    #   owner: 'user',
    #   perms: '0770',
    #   space_quota: '5T',
    #   ns_quota: '500000'
    # }
  }
end

# HDFS Projects Directory Configuration
default['bcpc']['hadoop']['dir_creation']['projects'].tap do |projects|
  # default entry values
  projects['defaults'] = {
    owner: 'hdfs',
    group: 'hdfs',
    perms: '1771',
    space_quota: node['bcpc']['hadoop']['hdfs']['groups']['space_quota'],
    ns_quota: node['bcpc']['hadoop']['hdfs']['groups']['ns_quota']
  }

  projects['dirinfo'] = {
    ## Example dirinfo entry:
    # project: {
    #   owner: 'user',
    #   group: 'group',
    #   perms: '1770',
    #   space_quota: '30T',
    #   ns_quota: '10000000'
    # }
  }
end

