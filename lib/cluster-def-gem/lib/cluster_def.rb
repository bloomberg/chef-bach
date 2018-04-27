# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# This module holds utility methods shared between repxe_host.rb,
# cluster_assign_roles.rb and Vagrantfile
# NOTE: Testing should be done with ChefDK and Vagrant rubys
#
# Most of the methods pertain to cluster.txt and its contents; should not
# contact the Chef server, use Chef client or VirtualBox.
#
# Workaround log spam in older versions of ChefDK.
#
# https://github.com/berkshelf/berkshelf/pull/1668/
# https://github.com/intridea/hashie/issues/394
#
begin
  require 'hashie'
  require 'hashie/logger'
  Hashie.logger.level = Logger.const_get 'ERROR'
  Hashie.logger = Logger.new(nil)
rescue LoadError
end

require 'json'
# TODO: Ia there a better way of handling this? Rodley has a lot of requirements
begin
  require 'chef-vault'
  require 'ridley'
  Ridley::Logging.logger.level = Logger.const_get 'ERROR'
rescue LoadError
  puts 'chef-vault or ridle has not yet been installed'
end

require 'ohai'
require 'faraday'
require 'chef'

module BACH
  class ClusterDef
    def initialize(node_obj: nil, repo_dir: nil)
      # bogus VirtualBox MAC (keep the vendor OUI set to VirtualBox's)
      @node_obj = node_obj
      @repo_dir = repo_dir
      @cluster_def = nil
    end

    # Return the default cluster.txt data
    # Returns: Array of cluster.txt lines
    # Raise: if the file is not found
    def cluster_txt
      File.readlines(File.join(repo_dir, 'cluster.txt'))
    end

    def fqdn(entry)
      if (entry[:dns_domain])
        entry[:hostname] + '.' + entry[:dns_domain]
      else
        entry[:hostname]
      end
    end

    def get_entry(name)
      fetch_cluster_def.select do |ee|
        ee[:hostname] == name || fqdn(ee) == name
      end.first
    end

    def validate_node_number?(nn)
      # node number must either be '-' or a positive integer
      # 1..255
      if nn != '-' && nn.to_i < 1 || nn.to_i > 2_147_483_646 then
        false
      else
        true
      end
    end

    def validate_cluster_def(cluster_def, fields)
        cdef_copy = cluster_def.reject { |row| row[:runlist] == 'SKIP' }
        # validate columns each row has the same number of fields as fields
        faulty_rows = cdef_copy.select { |row| row.length != fields.length }
        if faulty_rows.length.positive? then
          faulty_rows.each { |row| puts row }
          fail "Retreived cluster data appears to be invalid -- missing columns"
        end
        # validate node ids
        if (cluster_def.select{ |row| validate_node_number?(row[:node_id]) == false }).length.positive?  then
          fail "Retreived cluster data appears to be invalid -- node IDs must be positive integers"
        end
    end

    def parse_cluster_def(cluster_def)
      # parse something that looks like cluster.txt and memorize the result
      fields = [
                :node_id,
                :hostname,
                :mac_address,
                :ip_address,
                :ilo_address,
                :cobbler_profile,
                :dns_domain,
                :runlist
               ]

        # This is really gross because Ruby 1.9 lacks Array#to_h.
        cdef = cluster_def.map do |line|
          entry = Hash[*fields.zip(line.split(' ')).flatten(1)]
          entry.merge({fqdn: fqdn(entry)})
        end
        # field size check will fail if we do not do this
        fields += [:fqdn]
        validate_cluster_def(cdef, fields)
        cdef
    end

    # combines local cluster.txt access with http call to cluster data
    def fetch_cluster_def
      if @cluster_def != nil then
        @cluster_def
      end

      # This will always fail, unless we have a node object to query
      @cluster_def = fetch_cluster_def_http

      # If @cluster_def is still nil after the http attempt, fall back.
      unless @cluster_def
        $stderr.puts 'WARNING: Attempting to read cluster definition from ' \
          'local disk, after a failed HTTP request'
        @cluster_def = fetch_cluster_def_local
      end
    end

    # fetch cluster definition via http
    def fetch_cluster_def_http
      unless @node_obj
        return nil
      else
        begin
          cluster_def_url = 'http://' \
            "#{@node_obj[:bcpc][:bootstrap][:server]}" \
            "#{@node_obj[:bcpc][:bootstrap][:cluster_def_path]}"

          response = Faraday.new(proxy: '').get cluster_def_url

          if response.success? then
            parse_cluster_def(response.body.split("\n"))
          else
            nil
          end
        rescue Exception => http_e
          puts http_e
          puts http_e.backtrace
          return nil
        end
      end
    end

    # locally access cluster.txt
    def fetch_cluster_def_local
      parse_cluster_def(File.readlines(File.join(repo_dir, 'cluster.txt')))
    end

    def repo_dir
      @repo_dir || '/home/vagrant/chef-bcpc'
    end
  end
end
