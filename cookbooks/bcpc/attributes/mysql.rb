# Memory where InnoDB caches table and index data (in MB). Default is 128M.
default['bcpc']['mysql']['innodb_buffer_pool_size'] =
  ([(node[:memory][:total].to_i / 1024 * 0.02).floor, 128].max)

# Maximum connections per MySQL host. The MySQL default is 151.
default['bcpc']['mysql']['max_connections'] = 500

# This attribute controls if chef will reissue a bootstrap-pxc in case none of
# heads return with a positive response from the xinetd service
# This is used to facilitate the automated build, and will be overridden 
# to true in the environment file in production an operator may want to
# first examine grastate before choosing where to bootstrap-pxc
default['bcpc']['mysql']['bootstrap_on_error'] = false
