require 'spec_helper'
bins_dir = '/home/vagrant/chef-bcpc/bins'

chef_path = File.join(bins_dir,'chef_12.4.1-1_amd64.deb')

describe file(chef_path) do
  it { should be_file }
end

describe command("dpkg --info #{chef_path}") do
  its(:exit_status) { should eq 0 }
  its(:stdout){ should contain('Version: 12') }
end

chef_server_path = File.join(bins_dir,'chef-server-core_12.1.2-1_amd64.deb')

describe file(chef_server_path) do
  it { should be_file }
end

describe command("dpkg --info #{chef_server_path}") do
  its(:exit_status) { should eq 0 }
  its(:stdout){ should contain('Version: 12') }
end
