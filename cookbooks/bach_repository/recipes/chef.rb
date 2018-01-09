#
# Cookbook Name:: bach_repository
# Recipe:: chef
#
require 'uri'

include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

chef_packages_hash =
  {
   chefdk:
   [
     node['bach']['repository']['chefdk']['url'],
     node['bach']['repository']['chefdk']['sha256']
   ],
   chef:
   [
     node['bach']['repository']['chef']['url'],
     node['bach']['repository']['chef']['sha256']
   ],
   chef_server:
   [
     node['bach']['repository']['chef_server']['url'],
     node['bach']['repository']['chef_server']['sha256']
   ]
  }

chef_packages_hash.values.each do |package_url, package_checksum|

  package_name = ::File.basename(package_url)
  target_path = ::File.join(bins_dir, package_name)

  remote_file target_path do
    source package_url
    mode 0444
    checksum package_checksum
    # For whatever reason, these S3 mirrors are not very reliable.
    retries 8
  end
end

#
# chef-install.sh is used by 'knife bootstrap' to install Chef from
# the local bcpc repo, instead of attempting to reach out to the
# internet for the Omnitruck API.
#
download_url = URI.join(node['bach']['repository']['chef_url_base'],
                        File.basename(chef_packages_hash[:chef][0]))

checksum = chef_packages_hash[:chef][1]

template "#{bins_dir}/chef-install.sh" do
  source 'chef-install.sh.erb'
  mode 0555
  variables({
             download_url: download_url,
             sha256sum: checksum
            })
end
