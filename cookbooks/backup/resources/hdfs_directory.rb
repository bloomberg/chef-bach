# Cookbook Name:: backup
# Custom hdfs directory resource
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

resource_name :hdfs_directory

property :hdfs, String, required: true
property :path, String, name_property: true
property :admin, String, default: 'hdfs'
property :source, String
property :owner, String
property :group, String
property :mode, String

action_class do
  def execute(command, user=admin, timeout=90)
    require 'mixlib/shellout'
    Chef::Log.info("Running command(#{user}): #{command}")
    return Mixlib::ShellOut.new("sudo -u #{user} " + command, timeout: timeout).run_command
  end
end

action :create do
  # create the directory
  Chef::Log.info("HDFS dir #{path} creation")
  execute("hdfs dfs -mkdir -p #{hdfs}/#{path}", admin).error!

  # set the owner and group
  if !(owner.nil? || group.nil?)
    execute("hdfs dfs -chown #{owner}:#{group} #{hdfs}/#{path}", admin).error!
  elsif !owner.nil?
    execute("hdfs dfs -chown #{owner} #{hdfs}/#{path}", admin).error!
  elsif !group.nil?
    execute("hdfs dfs -chgrp #{group} #{hdfs}/#{path}", admin).error!
  end

  # set permissions
  if !mode.nil?
    execute("hdfs dfs -chmod #{mode} #{hdfs}/#{path}", admin).error!
  end
end

action :put do
  Chef::Log.info("Copying #{path} to HDFS")
  execute("hdfs dfs -put -f -p #{source} #{hdfs}/#{path}", admin).run_command.error!
end

action :delete do
  # speculative, recursive delete. (ignores error)
  Chef::Log.info("HDFS dir #{path} deletion")
  execute("hdfs dfs -rm -r -f #{hdfs}/#{path}", admin)
end

action :nothing do
end
