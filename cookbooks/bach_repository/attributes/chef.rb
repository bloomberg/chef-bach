default['bach']['repository']['chefdk']['url'] = \
  'https://packages.chef.io/files/stable/chefdk/2.4.17/ubuntu/' \
  '14.04/chefdk_2.4.17-1_amd64.deb'
default['bach']['repository']['chefdk']['sha256'] = \
  '15c40af26358ba6b1be23d5255b49533fd8e5421f7afbc716dcb94384b92e1b0'
default['bach']['repository']['chef']['url'] = \
  'https://packages.chef.io/repos/apt/stable/ubuntu/' \
  '14.04/chef_12.21.31-1_amd64.deb'
default['bach']['repository']['chef']['sha256'] = \
  '61656daa5f22ea31a93b602a88be196b0cc7033b1674f1bd195e4b679a1784a7'
# it does not appear that there is a 14.04 version of the ancient Chef-Server we use
default['bach']['repository']['chef_server']['url'] = \
  'https://packages.chef.io/files/stable/chef-server/12.17.33/' \
  'ubuntu/14.04/chef-server-core_12.17.33-1_amd64.deb'
default['bach']['repository']['chef_server']['sha256'] = \
  '2800962092ead67747ed2cd2087b0e254eb5e1a1b169cdc162c384598e4caed5'
default['bach']['repository']['chef_url_base'] = 'https://packages.chef.io/repos/apt/stable/ubuntu/14.04/'
default['bach']['repository']['chef_server_ip'] = '127.0.0.1'
default['bach']['repository']['chef_server_fqdn'] = 'localhost'
