#
# Cookbook Name:: bcpc-centos
# Recipe:: ganglia
#
# Copyright 2013, Bloomberg L.P.
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

# base-installed ganglia will interfere with the Ambari-controlled version
# so disable it

service "gmond" do
  action [ :stop ]
end

service "gmetad" do
  action [ :stop ]
end

bash "disable gmond" do
  user "root"
  code <<-EOH
  /sbin/chkconfig gmond off
  EOH
end

bash "disable gmetad" do
  user "root"
  code <<-EOH
  /sbin/chkconfig gmetad off
  EOH
end
