Vagrant.configure('2') do |config|
  config.vm.box = 'bento/ubuntu-14.04'

  config.vm.define 'bootstrap' do |bs|
    bs.vm.hostname = 'bootstrap.bcpc.example.com'

    # FIXME calculate subnets from Test-Laptop.json
    bs.vm.network :private_network, ip: '10.0.100.3', netmask: '255.255.255.0'

    config.vm.provider :virtualbox do |vb|
      vb.cpus = ENV.fetch 'BOOTSTRAP_VM_CPUs', 4
      vb.memory = ENV.fetch 'BOOTSTRAP_VM_MEM', 8192
    end

    config.vm.synced_folder '.', '/home/vagrant/chef-bcpc', type: 'rsync',
        rsync__exclude: %w(vendor Gemfile.lock .kitchen .chef)
    config.vm.synced_folder '../cluster', '/home/vagrant/cluster', type: 'rsync'

    chefdk_version = ENV.fetch 'CHEFDK_VERSION', '1.2.22'
    omnibus_url = ENV.fetch 'OMNIBUS_URL', 'https://omnitruck.chef.io/install.sh'
    config.vm.provision 'deploy-chefdk', type: 'shell', path: omnibus_url,
        args: ['-P', 'chefdk', '-v', chefdk_version], run: 'never'
  end

  6.times do |idx|
    config.vm.define "node#{idx}"  do |n|
      n.vm.hostname = "node#{idx}.bcpc.example.com"
      offset = 10 + idx
      # FIXME calculate subnets from Test-Laptop.json
      n.vm.network :private_network, ip: "10.0.100.#{offset}", netmask: '255.255.255.0'

      # Data Disks
      n.vm.provider :virtualbox do |vb|
        4.times do |i|
          port = i + 2 # ubuntu/trusty64 has port 0 for the root disk
          vb.customize ['createhd', '--filename', ".vagrant/machines/node#{idx}/node#{idx}-disk#{i}.vdi", '--size', 40 * 1024]
          # "SATA Controller" is the prebuilt controller in bento/ubuntu-14.04
          vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', port, '--type', 'hdd', '--medium', ".vagrant/machines/node#{idx}/node#{idx}-disk#{i}.vdi"]
        end
      end
    end
  end


  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.cpus = ENV.fetch 'CLUSTER_VM_CPUs', 4
    vb.memory = ENV.fetch 'CLUSTER_VM_MEM', 8192
  end
end
