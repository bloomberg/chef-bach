#
# Cookbook Name:: bcpc
# Recipe:: chef vault install
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

# This recipe should probably be removed entirely.
log 'vault-download-noop' do
  message 'This recipe should always be a no-op, because the vault gem ' \
          'was downloaded by the bach_repository::gems recipe in a chef ' \
          'local-mode session before the first chef run.'
  level :info
end

include_recipe 'bcpc::bach_repository_wrapper'
include_recipe 'bach_repository::gems'
