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
  @current_resource = Chef::Resource::WebhdfsHdfsTemplate.new(new_resource.name)
  effective_user = Etc.getpwuid(Process.uid).name
  @user = new_resource.user == nil ? effective_user : new_resource.user
  @kerberos = new_resource.kerberos == nil ? "off" : new_resource.kerberos
  @client, @host, @port = get_active_host(new_resource.hosts, @user, @kerberos)
  if @client == nil
    raise WebHDFS::Error.new("Unable to find an active name node")
  end
  @mode = new_resource.mode
  @path = new_resource.path
  @owner = new_resource.owner
  @source = new_resource.source
  @group = new_resource.group
  @variables = new_resource.variables
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
    return client, host, port if dir_exists?(client, "/")
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

# Action to create a file from template on HDFS
#
# Example
#
#   webhdfs_hdfs_template "/user/tony/tmp.txt" do
#     source 'tmp.erb'
#     owner 'guest'
#     group 'my'
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
#     variables ({
#       :var1 => 'val1',
#       :var2 => 'val2'
#     })
#     action :create
#   end
#
action :create do
require 'webhdfs'
require 'webhdfs/fileutils'
  converge_by("Create new file #{ @path }") do
    existed = false
    if file_exists?(@client, @path)
      existed = true
    end
    sourcefile = @source
    variables = @variables
    copied = false
    begin  
# copy the source file to a certain path on client machine first
      tmpfile = Tempfile.new('tmp_template')
      localpath = tmpfile.path
      template localpath do
        source sourcefile if sourcefile != nil
        variables variables if variables != nil
        action :nothing
      end.run_action(:create)
# upload the file to hdfs
      WebHDFS::FileUtils.set_server(@host, @port, @user)
      if @mode != nil
        WebHDFS::FileUtils.copy_from_local(localpath, @path, :mode => @mode, :overwrite => true)
      else
        WebHDFS::FileUtils.copy_from_local(localpath, @path, :overwrite => true)
      end
      copied = true
      tmpfile.close
      file localpath do
        action :delete
      end
      @filemeta = @client.stat(@path)
      hdfs_file_chown
      Chef::Log.info("#{ @path } created on hdfs according to template #@source")
      #@new_resource.updated_by_last_action(true)
    rescue WebHDFS::ServerError => e
      begin
        @client.delete(@path) if copied == true && existed == false
      rescue WebHDFS::ServerError => ex
        Chef::Log.error "clean up for template operation failed : #{ ex }!"
      end
      raise WebHDFS::ServerError.new(e)
    end
  end
end
 
# Action to create a file from template if it is missing on HDFS
#
# Example
#
#   webhdfs_hdfs_template "/user/tony/tmp.txt" do
#     source 'tmp.erb'
#     owner 'guest'
#     group 'my'
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
#     variables ({
#       :var1 => 'val1',
#       :var2 => 'val2'
#     })
#     action :create_if_missing
#   end
#
action :create_if_missing do
require 'webhdfs'
require 'webhdfs/fileutils'
  converge_by("Create file if missing #{ @path }") do
    copied = false
    begin
      if !file_exists?(@client, @path)
        tmpfile = Tempfile.new('tmp_template')
        localpath = tmpfile.path
        sourcefile = @source
        variables = @variables
        ::File.new(localpath,"w")
        template localpath do
          source sourcefile if sourcefile != nil
          variables variables if variables != nil
          action :nothing
        end.run_action(:create)
        WebHDFS::FileUtils.set_server(@host, @port, @user)
        if @mode != nil
          WebHDFS::FileUtils.copy_from_local(localpath, @path, :mode => @mode)
        else
          WebHDFS::FileUtils.copy_from_local(localpath, @path)
        end
        copied = true
        tmpfile.close
        file localpath do
          action :delete
        end
        @filemeta = @client.stat(@path)
        hdfs_file_chown
        Chef::Log.info("#{ @path } created on hdfs according to template #@source")
        @new_resource.updated_by_last_action(true)
      else
        Chef::Log.info "File #{ @path } already exist, nothing to do!"
      end
      Chef::Log.debug "File metadata is: #{ @filemeta }"
    rescue WebHDFS::ServerError => e
      begin
        @client.delete(@path) if copied == true && existed == false
      rescue WebHDFS::ServerError => ex
        Chef::Log.error "clean up for template create operation failed : #{ ex }!"
      end
      raise WebHDFS::ServerError.new(e)
    end
  end
end

# Action to delete a file from HDFS
#
# Example
#
#   webhdfs_hdfs_template "/user/tony/tmp.txt" do
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
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

# Action to set access and modification time of an existed file on hdfs
#
#   webhdfs_hdfs_template "/user/tony/tmp.txt" do
#     user 'tony'
#     host 'bloomberg-bcpc.com:14000'
#     action :touch
#   end
#
action :touch do
require 'webhdfs'
  converge_by("Touch file #{ @path }") do
    if file_exists?(@client, @path)
      time = (Time.now.to_f * 1000).to_i
      @client.touch(@path, :modificationtime => time, :accesstime => time)
      Chef::Log.info("#{ current_resource } updated atime and mtime to #{ time }")
      @new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "File #{ @path } does not exist, nothing to do!"
    end
    Chef::Log.debug "File metadata is: #{ @client.stat(@path) }"
  end
end

