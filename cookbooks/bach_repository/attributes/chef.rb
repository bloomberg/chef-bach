default['bach']['repository']['chefdk']['url'] = \
  'https://packages.chef.io/files/stable/chefdk/2.5.3/ubuntu/' \
  '14.04/chefdk_2.5.3-1_amd64.deb'
default['bach']['repository']['chefdk']['sha256'] = \
  'b6cd2c84e2ecbf35238dd6c360eadbab89f44e1c5a7b54430828529fa403204f'
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
