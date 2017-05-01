#
# Cookbook Name:: bcpc
# Recipe:: mysql_client
#
# Copyright 2013, Bloomberg Finance L.P.
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

# Include the percona apt repository using the 'bcpc_repo' definition.
bcpc_repo 'percona'

#
# The modern percona packages require us to use the percona client.
#
# This should be source-compatible with standard MySQL clients, since
# it uses the same sonames.
#
package 'libperconaserverclient18-dev' do
  action :upgrade
end

%w{mysql2 sequel}.each do |gem_name|
  chef_gem gem_name.to_s do
    options "--clear-sources -s #{get_binary_server_url}"
    compile_time false
  end
end
