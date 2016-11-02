#
# Cookbook Name:: bach_repository
# Recipe:: jmxtrans
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/jmxtrans-256-dist.tar.gz" do
  source 'http://central.maven.org/maven2/org/jmxtrans/jmxtrans/256/' \
    'jmxtrans-256-dist.tar.gz'
  user 'root'
  group 'root'
  mode 0444
  checksum '3219cc40954f62cc9fba4fddb1ff70a3ffce1eac63f1d37ec6cb72b90a48999f'
end

