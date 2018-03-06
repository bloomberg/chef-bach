#
# Cookbook :: ambari
# Spec :: default
# Copyright 2018, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

 describe file('/etc/ambari-server/conf/ambari.properties') do
   it { should exist }
 end

 describe file('/etc/ambari-server/conf/password.dat') do
   it { should exist }
 end

 describe command('ambari-server status') do
   its(:stdout) { should contain('Ambari Server running') }
 end

end
