#
# Cookbook Name:: bach_sqoop
# Recipe:: default
#
# Copyright 2015, Bloomberg Finance L.P.
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

package 'sqoop' do
  action [:install, :upgrade]
end

# Install Sqoop Bits
template "/etc/sqoop/conf/sqoop-env.sh" do
  source "sq_sqoop-env.sh.erb"
  mode "0444"
  action :create
end

directory node[:bach][:sqoop][:install_dir] do
  action :create
  mode 0555
end

directory node[:bach][:sqoop][:lib_dir] do
  action :create
  mode 0555
end

# Download any JDBC jars required for database connectivity.
jdbc_hash = node[:bach][:sqoop][:jdbc_jars]
jdbc_hash.keys.each do|jar_file|
  remote_file node[:bach][:sqoop][:lib_dir] + '/' + jar_file do
    source jdbc_hash[jar_file]['url']
    checksum jdbc_hash[jar_file]['checksum']
    mode 0444
  end
end
