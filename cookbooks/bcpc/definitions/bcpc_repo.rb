#
# Cookbook Name:: bcpc
# Definition:: bcpc_repo
#
# Copyright 2016, Bloomberg Finance L.P.
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
# The bcpc_repo definition populates an apt_repository resource with
# environment attributes.  Any attributes passed directly to the
# resource will override the environment.
#
define :bcpc_repo do
  repo_name = params[:name]

  # Check for a pre-2.0 attribute structure, and barf if found.
  if node[:bcpc][:repos][repo_name].is_a?(String)
    raise "Invalid entry in node[:bcpc][:repos] for #{repo_name}! " \
      "Do you have pre-2.0 repo definitions in your environment?"
  elsif node[:bcpc][:repos][repo_name].nil?
    raise "No repo definition found for '#{repo_name}'!"
  end
  
  attrs = node[:bcpc][:repos][repo_name].merge(params)

  apt_repository repo_name do
    attrs.each do |key, value|
      send(key.to_sym, value)
    end
  end
end

