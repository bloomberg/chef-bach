#
# Cookbook Name:: hdfsdu
# Recipe:: build
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
# Builds and packages HDFSDU codebase
#
# Pre-requisites: git, java and maven are installed

require 'fileutils'

node.force_default['maven']['repositories'] = \
  (node['maven']['repositories'] || nil) + \
  [node['hdfsdu']['maven']['repository']]

hdfsdu_version = node['hdfsdu']['version']
target_filename = "hdfsdu-service-#{hdfsdu_version}-bin.zip"
target_filepath = "#{node['hdfsdu']['bin_dir']}/#{target_filename}"
build_user = node['hdfsdu']['build_user']
source_code_location = "#{Chef::Config['file_cache_path']}/hdfsdu"

git source_code_location do
  repository node['hdfsdu']['repo_url']
  revision node['hdfsdu']['repo_branch']
  action :sync
  not_if { ::File.exist?(target_filepath) }
end

bash 'chown hdfsdu' do
  code "chown -R #{build_user} #{source_code_location}"
  only_if { ::File.directory?(source_code_location) }
end

bash 'compile_hdfsdu_service' do
  cwd "#{source_code_location}/service"
  user build_user
  code %(
    sed -iE \
      's/#{node['hdfsdu']['default_db_port']}/#{node['hdfsdu']['db_port']}/' \
      src/main/java/com/twitter/hdfsdu/Database.java
    mvn clean assembly:assembly -DdescriptorId=bin -DskipTests
  )
  only_if { ::File.directory?(source_code_location) }
end

ruby_block 'copy_hdfsdu_bin' do
  block do
    FileUtils.cp "#{source_code_location}/service/target/#{target_filename}",
                 target_filepath
  end
  only_if { ::File.directory?(source_code_location) }
end

file target_filepath do
  mode '0755'
end

bash 'create_hdfsdu_pig_tar' do
  cwd "#{source_code_location}/service"
  code %(
    tar -zcvf \
      #{node['hdfsdu']['bin_dir']}/hdfsdu-pig-src-#{hdfsdu_version}.tgz \
      ../pig/src
  )
  only_if { ::File.directory?(source_code_location) }
end

file "#{node['hdfsdu']['bin_dir']}/hdfsdu-pig-src-#{hdfsdu_version}.tgz" do
  mode '0755'
end

bash 'cleanup' do
  cwd ::File.dirname(source_code_location)
  code %(
    rm -rf #{::File.basename(source_code_location)}
  )
  only_if { ::File.directory?(source_code_location) }
end
