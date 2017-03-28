require 'chef/config'
require 'chef/log'
require 'chef/resource/directory'
require 'chef/provider'
require 'chef/search/query'
require_relative 'utils'

class HdfsDirectoryError < RuntimeError; end

class Chef
  class Provider::HdfsDirectory < Chef::Provider
  
    def whyrun_supported?
      true
    end

    def load_current_resource
      require 'webhdfs'
      @current_resource ||= Chef::Resource::Directory.new(@new_resource.name)
      @current_resource.path(@new_resource.path)
      @current_resource.mode(@new_resource.mode)
      @current_resource.owner(@new_resource.owner)
      @current_resource.recursive(@new_resource.recursive)
      @current_resource.group(@new_resource.group)
      if !set_active_namenode?
        raise HdfsDirectoryError.new("Unable to find an active name node")
      end
    end

    def action_create 
      converge_by("Create new directory #{@new_resource.path}") do
        if !dir_exists?(@new_resource.path)
          @client.mkdir(@new_resource.path, :permission => [ @new_resource.mode == nil  ? 0755.to_s(8) : @new_resource.mode.to_s(8) ] )
          @client.chown(@new_resource.path, :owner => [ @new_resource.owner == nil ? 'hdfs':@new_resource.owner ] , :group => [ @new_resource.group == nil ? 'hdfs':@new_resource.group ] )
          if !dir_exists?(@new_resource.path)
            raise HdfsDirectoryError.new("Can not create directory")
          end
        else
          if @new_resource.mode != nil && ( @dirmeta['permission'] != @new_resource.mode.to_s(8) )
            @client.chmod(@new_resource.path, @new_resource.mode.to_s(8)) 
          end

          if  ( @new_resource.owner != nil && @new_resource.group != nil ) && ( @dirmeta['owner'] != @new_resource.owner && @dirmeta['group'] != @new_resource.group )
            @client.chown(@new_resource.path, :owner => @new_resource.owner, :group => @new_resource.group)
          elsif @new_resource.owner != nil && ( @dirmeta['owner'] != @new_resource.owner )
            @client.chown(@new_resource.path, :owner => @new_resource.owner, :group => @dirmeta['group'])
          elsif @new_resource.group != nil && ( @dirmeta['group'] != @new_resource.group )
            @client.chown(@new_resource.path, :owner => @dirmeta['owner'], :group => @new_resource.group) 
          end
        end
      end     
    end

    def action_delete
      converge_by("Deleting directory #{@new_resource.name}") do
        begin
          if dir_exists?(@new_resource.path) && @client.delete(@new_resource.path, :recursive => [ @new_resource.recursive==true ? true:false ])
            Chef::Log.info "Deleted directory  #{@new_resource.name}"
          else
            Chef::Log.info "Directory '#{@new_resource.path}' cannot be deleted. Please make sure it is not a file."
          end
        rescue
          Chef::Log.info "Directory '#{@new_resource.path}' doesn't exists or it has subdirectroies. Please run with recursive flag set to true."
        end
      end
    end

    def get_namenodes( string )
      results = []
      Chef::Search::Query.new.search(:node, string) { |o| results << o }
      results.map! { |node| float_host(node.hostname) }
      Chef::Log.debug "Chef metadata search returned #{results}"
      return results
    end

    def dir_exists?(dirname)
      dirfound = false
        begin
          # Get stats for the resource passed 
          @dirmeta = @client.stat("#{dirname}")
          Chef::Log.debug "Directory metadata is #{@dirmeta}"
          # If resource is found in HDFS and is not a file
          if @dirmeta.length > 0 && @dirmeta['type'] == "DIRECTORY"
            dirfound = true
          end
          return dirfound
        rescue
          return dirfound
        end 
    end

    def set_active_namenode?
      nnfound = false
      nn_hosts = get_namenodes("recipes:*namenode*")
      Chef::Log.debug "Namenode hosts are #{nn_hosts}"
      nn_hosts.each do | nn |
        @client = WebHDFS::Client.new(nn, 50070, 'hdfs')
        if dir_exists?("/")
          nnfound = true
          break
        end
      end
        return nnfound
    end

  end
end
