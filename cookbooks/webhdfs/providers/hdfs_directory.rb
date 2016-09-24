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
  @current_resource = Chef::Resource::WebhdfsHdfsDirectory.new(new_resource.name)
  effective_user = Etc.getpwuid(Process.uid).name
  @user = new_resource.user == nil ? effective_user : new_resource.user
  @kerberos = new_resource.kerberos == nil ? "off" : new_resource.kerberos
  @client = get_active_host(new_resource.hosts, @user, @kerberos)
  if @client == nil
    raise WebHDFS::Error.new("Unable to find an active name node")
  end
  @current_resource.path(new_resource.path)
  @current_resource.mode(new_resource.mode == nil ? "0755" : new_resource.mode)
  @current_resource.owner(new_resource.owner)
  @current_resource.recursive(new_resource.recursive)
  @current_resource.group(new_resource.group)
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
    dirmeta = client.stat(path)
    Chef::Log.debug "Directory metadata is #{ dirmeta }"
    if dirmeta["type"] != "DIRECTORY"
      return false
    else
      return true
    end
  rescue SocketError, WebHDFS::FileNotFoundError => e
    Chef::Log.debug "#{e}!"
    return false
  end
end

def hdfs_chown
require 'webhdfs'
  converge_by("Create new directory #{ @new_resource.path }") do
    if @new_resource.owner != nil && @new_resource.group != nil && @new_resource.owner != @dirmeta['owner'] && @new_resource.group != @dirmeta['group']
      @client.chown(@new_resource.path, :owner => @new_resource.owner, :group => @new_resource.group)
    elsif @new_resource.owner != nil  && @new_resource.owner != @dirmeta['owner']
      @client.chown(@new_resource.path, :owner => @new_resource.owner)
    elsif @new_resource.group != nil && @new_resource.group != @dirmeta['group']
      @client.chown(@new_resource.path, :group => @new_resource.group)
    else
      return false
    end
    return true
  end
end
# Action to create a directory on HDFS
# If directory has already existed, then just set the permission and chown 
#
# Example
# 
#   webhdfs_hdfs_directory "/user/tony/tmp.txt" do
#     path '/user/tony/tmp'
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
#     owne 'tony'
#     action :create
#   end
#
action :create do
require 'webhdfs'
  converge_by("Create new directory #{ @new_resource.path }") do
    existed = false
    begin
      if !dir_exists?(@client, @new_resource.path)
        if @new_resource.mode != nil
          @client.mkdir(@new_resource.path, :permission => @new_resource.mode)
        else        
          @client.mkdir(@new_resource.path)
        end
        existed = true
        @dirmeta = @client.stat(@new_resource.path)
        hdfs_chown
        Chef::Log.info("#{ @new_resource.path } created on hdfs")
      else
        @dirmeta = @client.stat(@new_resource.path)
        if @new_resource.mode != nil && @dirmeta["permission"] != @new_resource.mode
          @client.chmod(@new_resource.path, @new_resource.mode)
          Chef::Log.info "#{ @new_resource } change mode to #{ @new_resource.mode }"
        end
        success = hdfs_chown
        Chef::Log.info "#{ @new_resource } change owner and group to #{ @new_resource.owner } and #{ @new_resource.group }" if success == true
      end
      @new_resource.updated_by_last_action(true)
      Chef::Log.debug "Directory metadata is #{ @dirmeta }"
    rescue WebHDFS::ServerError => e
      begin
        @client.delete(@new_resource.path) if existed == true
      rescue WebHDFS::ServerError => ex
        Chef::Log.error "clean up for create operation failed : #{ ex }"
      end
      raise WebHDFS::ServerError.new(e)
    end
  end
end

# Action to delete a directory from HDFS
# 
# Example
#
#   webhdfs_hdfs_directory "/user/tony/tmp" do
#     path '/user/tony/tmp'
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
#     owner 'tony'
#     recursive true
#     action :delete
#   end
#
action :delete do
require 'webhdfs'
  if !dir_exists?(@client, @new_resource.path)
    Chef::Log.info "Directory #{ @new_resource.path } does not exist, nothing to do!"
  else
    converge_by("Deleting directory #{ @new_resource.path }") do
      @client.delete(@new_resource.path, :recursive => [@new_resource.recursive != nil ? @new_resource.recursive : false])
      Chef::Log.info "Directory #{ @new_resource.path } has been deleted"
      @new_resource.updated_by_last_action(true)
    end
  end
end

