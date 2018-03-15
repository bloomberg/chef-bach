#
# Cookbook:: bach_ambari
# Recipe:: default
#
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

# configure ambari-server reposiory and installs ambari server.
include_recipe 'ambari::default'

# creates user, database and database schema for ambari server.
include_recipe 'bach_ambari::mysql_server_external_setup'

# It is required to download ambari kerberos file.
user "#{node['bcpc']['hadoop']['proxyuser']['ambari']}" do
  comment 'ambari user'
end

configure_kerberos 'ambari_kerb' do
  service_name 'ambari'
end

include_recipe 'ambari::ambari_server_setup'
include_recipe 'ambari::ambari_views_setup'

include_recipe 'bach_ambari::remove_sensitive_attributes'
