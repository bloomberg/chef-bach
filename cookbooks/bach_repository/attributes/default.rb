#
# "bins" contains all binaries and repositories, plus some builds
# "src" contains some builds
#
# The decision on whether to build in src_directory vs bins_directory
# was made by the old build_bins.sh.  For now, we are just replicating
# the behavior of the old script.
#
default['bach']['repository']['bins_directory'] = '/home/vagrant/chef-bcpc/bins'
default['bach']['repository']['src_directory'] = '/home/vagrant/chef-bcpc/src'

# What is this for?
default['bach']['repository']['apt_repo_version'] = '0.5.0'

# Apt signing keys.
default['bach']['repository']['private_key_path'] = '/home/vagrant/apt_key.sec'
default['bach']['repository']['public_key_path'] = 
  default['bach']['repository']['bins_directory'] + '/apt_key.pub'
default['bach']['repository']['ascii_key_path'] = 
  default['bach']['repository']['bins_directory'] + '/apt_key.asc'

# Apt repository location
default['bach']['repository']['apt_directory'] =
  default['bach']['repository']['bins_directory'] + '/dists/' + 
  default['bach']['repository']['apt_repo_version']
