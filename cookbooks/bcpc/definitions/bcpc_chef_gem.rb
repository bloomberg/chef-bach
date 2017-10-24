#
# Cookbook Name:: bcpc
# Definition:: bcpc_chef_gem
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

#
# The bcpc_chef_gem definition installs gems from the bootstrap using
# an execute resource.
#
# The chef_gem resource in chef-client versions prior to 13.0 cannot
# handle an air-gapped environment without setting a global
# Chef::Config[:rubygems_url].  Until we can move to chef-client 13.0,
# this will have to be our workaround.
#
define :bcpc_chef_gem do
  gem_name = params[:name]
  compile_time = params[:compile_time]
  gem_version = params[:version]
  additional_options = params[:options]

  compile_time_action = if compile_time
                          :run
                        else
                          :nothing
                        end

  converge_time_action = if compile_time
                           :nothing
                         else
                           :run
                         end

  gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s

  execute "bcpc_chef_gem_install_#{gem_name}" do
    command "#{gem_path} install #{gem_name} " \
      '-q --no-rdoc --no-ri ' \
      "-v '#{gem_version}' " \
      '--clear-sources ' \
      "-s #{get_binary_server_url} " +
      additional_options.to_s
    not_if "#{gem_path} list #{gem_name} -i -v '#{gem_version}'"
    environment ({ 'no_proxy' => URI.parse(get_binary_server_url).host })
    action converge_time_action
    umask 0022
  end.run_action(compile_time_action)

  # Make the just-installed gem available to 'require' by clearing caches.
  ruby_block "bcpc_chef_gem_clear_paths_#{gem_name}" do
    block do
      Gem.clear_paths
    end
    action converge_time_action
  end.run_action(compile_time_action)
end
