require 'spec_helper'
bins_dir = @node['bach']['repository']['bins_directory']
chef_client_deb = File.basename(@node['bach']['repository']['chef']['url'])
chef_server_deb = File.basename(
  @node['bach']['repository']['chef_server']['url'])

chef_path = File.join(bins_dir, chef_client_deb)

describe file(chef_path) do
  it { should be_file }
end

describe command("dpkg --info #{chef_path}") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should contain('Version: 12') }
end

chef_server_path = File.join(bins_dir, chef_server_deb)

describe file(chef_server_path) do
  it { should be_file }
end

describe command("dpkg --info #{chef_server_path}") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should contain('Version: 11') }
end
