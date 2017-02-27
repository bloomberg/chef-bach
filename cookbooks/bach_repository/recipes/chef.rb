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
      '14.04/x86_64/chefdk_1.1.16-1_amd64.deb',
    '7a1bed7f6eae3ae26694f9d3f47ce76d5e0cbbaba72dafcbc175e89ba0ac6dd9'
   ],
   chef:
   [
    'https://packages.chef.io/repos/apt/stable/ubuntu/' \
      '14.04/chef_12.19.36-1_amd64.deb',
    'fbf44670ab5b76e4f1a1f5357885dafcc79e543ccbbe3264afd40c15d604b6dc'
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
