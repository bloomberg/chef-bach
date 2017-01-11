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
    'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/' \
      '14.04/x86_64/chefdk_0.12.0-1_amd64.deb',
    '6fcb4529f99c212241c45a3e1d024cc1519f5b63e53fc1194b5276f1d8695aaa'
   ],
   chef:
   [
     'https://packages.chef.io/files/current/chef/12.18.24/ubuntu/' \
       '14.04/chef_12.18.24-1_amd64.deb',
    'ff57e8206dbe23862f2beac3a741e715d4f9838512736f15c6293f80e5139342'
   ],
   chef_server:
   [
    'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/' \
      '12.04/x86_64/chef-server_11.1.1-1_amd64.deb',
    'b6c354178cc83ec94bea40a018cef697704415575c7797c4abdf47ab996eb258'
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
download_url = URI.join(get_binary_server_url,
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
