#
# Cookbook Name:: bcpc
# Recipe:: 389ds
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

include_recipe "bcpc::default"

ruby_block "initialize-389ds-config" do
    block do
        make_config('389ds-admin-user', "admin")
        make_config('389ds-admin-password', secure_password)
        make_config('389ds-rootdn-user', "cn=Directory Manager")
        make_config('389ds-rootdn-password', secure_password)
    end
end

package "389-ds" do
    action :upgrade
end

template "/tmp/389ds-install.inf" do
    source "389ds-install.inf.erb"
    owner "root"
    group "root"
    mode 00600
end

bash "setup-389ds-server" do
	user "root"
	code <<-EOH
		setup-ds-admin --file=/tmp/389ds-install.inf -k -s
	EOH
	not_if "test -d /etc/dirsrv/slapd-#{node.hostname}"
end
