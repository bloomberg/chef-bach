#
# Cookbook Name:: bcpc
# Recipe:: packages
#
# Copyright 2017, Bloomberg Finance L.P.
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

# Useful system packages
%w(
  bc
  fio
  git
  htop
  iotop
  ldap-utils
  libsasl2-modules-gssapi-mit
  lzop
  p7zip-full
  powertop
  silversearcher-ag
  sysstat
  vim-nox
  xclip
  zip
).each do |pkg|
  package pkg do
    action :upgrade
  end
end

#
# One particularly unhelpful system package -- frequently consumes
# 100% of CPU, but we don't send the metrics anywhere.
#
package 'pcp' do
  action :purge
end
