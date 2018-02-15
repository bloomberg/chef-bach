# Cookbook Name:: bcpc
# Recipe:: cronjobs
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

# Base cronjobs/ pseudo-cronjobs that should be on all machines in the cluster.

clear_tmp = node['bcpc']['cronjobs']['clear_tmp']
execute 'clear /tmp' do
  command '/usr/bin/find /tmp -type f '\
          "-atime +#{clear_tmp['atime_age']} -delete && "\
          '/usr/bin/touch /var/lib/clear-temp.run'
  not_if do
    update_frequency = clear_tmp['frequency']
    update_file = '/var/lib/clear-temp.run'
    ::File.exist?(update_file) &&
      ::File.mtime(update_file) > Time.now - update_frequency
  end
end
