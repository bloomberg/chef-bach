require 'spec_helper'

describe package('zookeeper-server') do
  it { should be_installed }
end

describe user('zookeeper') do
  it { should exit }
end

describe group('zookeeper') do
  it { should exit }
end

describe service('zookeeper-server') do
  it { should be_running }
end

describe process("zookeeper") do
  it { should be_running }
  its(:user) { should eq "zookeeper" }
  its(:group) { should eq "zookeeper" }
end

describe port(2181) do
  it { not should be_listening.on('127.0.0.1').with('tcp') }
  it { should be_listening.on(o['ipaddress']).with('tcp') }
end
