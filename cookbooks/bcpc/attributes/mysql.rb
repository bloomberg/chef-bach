# Memory where InnoDB caches table and index data (in MB). Default is 128M.
default['bcpc']['mysql']['innodb_buffer_pool_size'] =
  ([(node[:memory][:total].to_i / 1024 * 0.02).floor, 128].max)

# Maximum connections per MySQL host. The MySQL default is 151.
default['bcpc']['mysql']['max_connections'] = 500
