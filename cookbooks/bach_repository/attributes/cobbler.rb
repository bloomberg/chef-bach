default['cobbler']['source']['build_user'] = 'vagrant'
default['cobbler']['source']['build_group'] = 'vagrant'
default['cobbler']['source']['dir'] = "#{node['bach']['repository']['src_directory']}/cobbler_build"
default['cobbler']['bin_dir'] = node['bach']['repository']['bins_directory']

# need to duplicate this logic from the Cobbler cookbook as this gets run in the
# attributes file there (before we have set bin_dir)
cobbler_target_filename = 'cobbler.rpm' if node['platform_family'] == "rhel"
cobbler_target_filename = 'cobbler.deb' if node['platform_family'] == "debian"
default['cobbler']['target']['filepath'] = ::File.join(node['cobbler']['bin_dir'], cobbler_target_filename)
