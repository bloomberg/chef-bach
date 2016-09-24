#
# Cookbook Name:: webhdfs
# Recipe:: hdfs_directory
#
# Copyright 2015, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/log'
require 'etc'

# To enable -W/--why-run option of chef-client
def whyrun_supported?
  true
end

def load_current_resource
require 'webhdfs'
  @current_resource = Chef::Resource::WebhdfsHdfsFile.new(new_resource.name)
  effective_user = Etc.getpwuid(Process.uid).name
  @user = new_resource.user == nil ? effective_user : new_resource.user
  @kerberos = new_resource.kerberos == nil ? "off" : new_resource.kerberos
  @client = get_active_host(new_resource.hosts, @user, @kerberos)
  if @client == nil
    raise WebHDFS::Error.new("Unable to find an active name node")
  end
  @mode = new_resource.mode
  @path = new_resource.path
  @owner = new_resource.owner
  @content = new_resource.content
  @group = new_resource.group
  @current_resource
end

def get_active_host(hosts,user,kerberos)
require 'webhdfs'
  return nil if hosts == nil || hosts == /\s*/
  nn_hosts = hosts.split(",")
  nn_hosts.each do |node|
    host,port = node.split(/:/)
    if kerberos == "off"
      client = WebHDFS::Client.new(host.strip,port.strip,user)
    else
      client = WebHDFS::Client.new(host.strip,port.strip)
      client.kerberos = true
    end
    return client if dir_exists?(client, "/")
  end
  return nil
end

def dir_exists?(client, path)
require 'webhdfs'
  begin
    dirmeta = client.stat("#{ path }")
    Chef::Log.debug "Directory metadata is #{ dirmeta }"
    if dirmeta["type"] == "DIRECTORY"
      return true
    else
      return false
    end
  rescue SocketError => e
    Chef::Log.debug "#{ e }!"
    return false
  end
end

def file_exists?(client, path)
require 'webhdfs'
  begin
    filemeta = client.stat("#{ path }")
    Chef::Log.debug "File metadata is #{ filemeta }"
    if filemeta["type"] == "FILE"
      return true
    else
      return false
    end
  rescue SocketError, WebHDFS::FileNotFoundError => e
    Chef::Log.debug "#{ e }!"
    return false
  end
end

def hdfs_file_chown
require 'webhdfs'
  if @owner != nil && @group != nil && @filemeta['owner'] != @owner && @filemeta['group'] != @group
    @client.chown(@path, :owner => @owner, :group => @group)
  elsif @owner != nil && @filemeta['owner'] != @owner
    @client.chown(@path, :owner => @owner)
  elsif @group != nil && @filemeta['group'] != @group
    @client.chown(@path, :group => @group)
  end
end

# Action to create a file on HDFS
#
# Example
# 
#   webhdfs_hdfs_file "/user/tony/tmp.txt" do
#     path '/user/tony/tmp.txt'
#     user 'tony'
#     hosts 'bloomberg-bcpc.com:14000,host2:8080'
#     owner 'tony'
#     action :create
#   end
#
action :create do
require 'webhdfs'
  converge_by("Create new file #{ @path }") do
    if file_exists?(@client, @path)
      existed = true
    else
      existed = false
    end
    created = false
    begin
      if @mode != nil
        @client.create(@path, @content, :overwrite => true, :permission => @mode)
      else
        @client.create(@path, @content, :overwrite => true)
      end
      created = true
      @filemeta = @client.stat(@path)
      hdfs_file_chown
      Chef::Log.info("#{ @path } created on hdfs")
      @new_resource.updated_by_last_action(true)
      Chef::Log.debug "File metadata is: #{ @filemeta }"
    rescue WebHDFS::ServerError => e
      begin
        @client.delete(@path) if existed == false && created == true
      rescue WebHDFS::ServerError => ex
        Chef::Log.error "clean up for File create operation failed : #{ ex }!"
      end
      raise WebHDFS::ServerError.new(e)
    end
  end
end

# Action to delete a file from HDFS
#
# Example
# 
#   webhdfs_hdfs_file "/user/tony/tmp.txt" do
#     path '/user/tony/tmp.txt'
#     user 'tony'
#     hosts 'bloomberg-bcpc.com:14000'
#     owner 'tony'
#     action :delete
#   end
#
action :delete do
require 'webhdfs'
  converge_by("Deleting file #{ @path }") do
    if file_exists?(@client, @path)
      @client.delete(@path)
      Chef::Log.info "File #{ @path } has been deleted"
      @new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "File #{ @path } does not exist, nothing to do!"
    end
  end
end

# Action to create a file if missing on HDFS
#
# Example
# 
#   webhdfs_hdfs_file "/user/tony/tmp.txt" do
#     path '/user/tony/tmp.txt'
#     user 'tony'
#     hosts 'bloomberg-bcpc.com:14000,host:8080'
#     owner 'tony'
#     action :create_if_missing
#   end
#
action :create_if_missing do
require 'webhdfs'
  converge_by("Create file #{ @path }") do
    created = false
    begin
      if !file_exists?(@client, @path)
        if @mode != nil
          @client.create(@path, @content, :permission => @mode)
        else
          @client.create(@path, @content)
        end
        created = true
        @filemeta = @client.stat(@path)
        hdfs_file_chown
        Chef::Log.info("File #{ @path } is created on hdfs")
        @new_resource.updated_by_last_action(true)
      else
        Chef::Log.info "File #{ @path } already exist, nothing to do!"
      end
      Chef::Log.debug "File metadata is: #{ @client.stat(@path) }"
    rescue WebHDFS::ServerError => e
      begin
        @client.delete(@path) if created == true
      rescue WebHDFS::ServerError => ex
        Chef::Log.error "clean up for File create operation failed : #{ ex }!"
      end
      raise WebHDFS::ServerError.new(e)
    end
  end
end

# Action to set access and modification time of an existed file on hdfs
#
#   webhdfs_hdfs_file "/user/tony/tmp.txt" do
#     user 'tony'
#     hosts 'bloomberg-bcpc.com:14000'
#     owner 'tony'
#     action :touch
#   end
#
action :touch do
require 'webhdfs'
  converge_by("Touch file #{ @path }") do
    if file_exists?(@client, @path)
      time = (Time.now.to_f * 1000).to_i
      @client.touch(@path, :modificationtime => time, :accesstime => time)
      Chef::Log.info("#{ @path } updated atime and mtime to #{ time }")
      @new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "File #{ @path } does not exist, nothing to do!"
    end
    Chef::Log.debug "File metadata is: #{ @client.stat(@path) }"
  end
end

