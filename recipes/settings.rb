require 'chef/provisioning/vagrant_driver'
with_driver 'vagrant'
 
vagrant_box 'precise64' do
  url 'https://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box'
end
 
with_machine_options :vagrant_options => {
  'vm.box' => 'precise64',
}

log "Chef environment: #{node.chef_environment}"

# Don't use proxies to talk to the bootstrap node's chef server.
Chef::Config['no_proxy'] = "#{bootstrap_fqdn},#{bootstrap_ip}"
ENV['no_proxy'] = Chef::Config['no_proxy']
log "Resetting no_proxy variables to: #{Chef::Config['no_proxy']}"

