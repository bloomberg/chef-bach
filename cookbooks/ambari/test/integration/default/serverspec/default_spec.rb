require 'spec_helper'

set :os , :family => 'ubuntu' , :release => 14.04

describe 'ambari::default' do
 it 'ambari-server is installed' do
   expect(package 'ambari-server').to be_installed
 end

 it 'dependency wget is installed' do
   expect(package 'wget').to be_installed
 end

 it 'dependency curl is installed' do
   expect(package 'curl').to be_installed
 end

 it 'dependency unzip is installed' do
   expect(package 'unzip').to be_installed
 end

 it 'dependency tar is installed' do
   expect(package 'tar').to be_installed
 end

 it 'dependency python2.7 is installed' do
   expect(package 'python2.7').to be_installed
 end

 it 'dependency openssl is installed' do
   expect(package 'openssl').to be_installed
 end

 it 'dependency postgresql-client-common is installed' do
   expect(package 'postgresql-client-common').to be_installed
 end

 it 'dependency postgresql-common is installed' do
   expect(package 'postgresql-common').to be_installed
 end

 it 'dependency ssl-cert is installed' do
   expect(package 'ssl-cert').to be_installed
 end

 it 'dependency libpq5 is installed' do
   expect(package 'libpq5').to be_installed
 end

 it 'dependency postgresql is installed' do
   expect(package 'postgresql').to be_installed
 end

 # it 'dependency postgresql-9.1 is installed' do
 #   expect(package 'postgresql-9.1').to be_installed
 # end

 # it 'dependency postgresql-client-9.1 is installed' do
 #   expect(package 'postgresql-client-9.1').to be_installed
 # end

# tests whether oracle java 8 is installed
 # describe file('/usr/lib/jvm/java-8-oracle-amd64') do
 #   it { should be_directory }
 #   it { should exist }
 # end

 describe file('/etc/ambari-server/conf/ambari.properties') do
   it { should exist }
 end

 describe file('/etc/ambari-server/conf/password.dat') do
   it { should exist }
 end

 describe command('ambari-server status') do
   its(:stdout) { should contain('Ambari Server running') }
 end

# it 'ambari server responds on port 8080' do
#   expect(port 8080).to be_listening 'tcp'
# end

 # agent specific tests
 # describe command('ambari-agent start') do
 #  its(:stdout) { should contain('Ambari Agent successfully started') }
 # end

# it 'ambari-agent responds on port 8440' do
#   expect(port 8440).to be_listening 'tcp'
# end

 # describe file('/etc/ambari-agent/conf/ambari-agent.ini') do
 #   it { should exist }
 # end
end
