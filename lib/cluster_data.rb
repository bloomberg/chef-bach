#
# This module holds utility methods shared between repxe_host.rb,
# cluster_assign_roles.rb and Vagrantfile
# NOTE: Testing should be done with ChefDK and Vagrant rubys
#
# Most of the methods pertain to cluster.txt and its contents; should not
# contact the Chef server, use Chef client or VirtualBox.
#

# pry is not required but nice to have
begin
  require 'pry'
rescue LoadError
end

#
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

module BACH
  #
  # Methods to get data about a BACH cluster
  #
  module ClusterData
    # bogus VirtualBox MAC (keep the vendor OUI set to VirtualBox's)
    BOGUS_VB_MAC = '08:00:27:C0:FF:EE'
    BIOS_COBBLER_PROFILE = 'bcpc_host_trusty'
    EFI_COBBLER_PROFILE = 'bcpc_host_trusty'

    def repo_dir
      # This file is in the 'lib' subdirectory, so the repo dir is its parent.
      File.expand_path('..', File.dirname(__FILE__))
    end

    def chef_environment_name
      File.basename(chef_environment_path).gsub(/.json$/, '')
    end

    def chef_environment_path
      env_files = Dir.glob(File.join(repo_dir, 'environments', '*.json'))

      if env_files.count != 1
        raise "Found #{env_files.count} environment files, " \
          'but exactly one should be present!'
      end

      env_files.first
    end

    #
    # Return the MAC address for a host empirically trying to talk to the host
    #
    def empirical_mac(entry)
      ping = Mixlib::ShellOut.new('ping', entry[:ip_address], '-c', '1')
      ping.run_command
      unless ping.status.success?
        puts "Ping to #{entry[:hostname]} (#{entry[:ip_address]}) failed, " \
          'checking ARP anyway.'
      end

      arp = Mixlib::ShellOut.new('arp', '-an')
      arp.run_command
      arp_entry = arp.stdout.split("\n")
                     .map(&:chomp)
                     .select { |l| l.include?(entry[:ip_address]) }
                     .first
      match_data =
        /(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w) .ether./.match(arp_entry.to_s)
      if !match_data.nil? && match_data.captures.count == 1
        mac = match_data[1]
        puts "Found #{mac} for #{entry[:hostname]} (#{entry[:ip_address]})"
        mac
      else
        raise 'Could not find ARP entry for ' \
          "#{entry[:hostname]} (#{entry[:ip_address]})!"
      end
    end

    #
    # Corrected MAC address
    #
    def corrected_mac(entry)
      # If it's a virtualbox VM, cluster.txt is wrong, and we need to
      # find the real MAC.
      if virtualbox_vm?(entry)
        empirical_mac(entry)
      else
        # Otherwise, assume cluster.txt is correct.
        entry[:mac_address]
      end
    end

    def fqdn(entry)
      if entry[:dns_domain]
        entry[:hostname] + '.' + entry[:dns_domain]
      else
        entry[:hostname]
      end
    end

    def get_entry(name)
      parse_cluster_txt(cluster_txt).select do |ee|
        ee[:hostname] == name || fqdn(ee) == name
      end.first
    end

    def virtualbox_vm?(entry)
      /^08:00:27/.match(entry[:mac_address])
    end

    # Return the default cluster.txt data
    # Returns: Array of cluster.txt lines
    # Raise: if the file is not found
    def cluster_txt
      File.readlines(File.join(repo_dir, 'cluster.txt'))
    end

    def parse_cluster_txt(entries)
      fields = [
        :hostname,
        :mac_address,
        :ip_address,
        :ilo_address,
        :cobbler_profile,
        :dns_domain,
        :runlist
      ]

      parsed = entries.map do |line|
        # This is really gross because Ruby 1.9 lacks Array#to_h.
        entry = Hash[*fields.zip(line.split(' ')).flatten(1)]
        entry.merge(fqdn: fqdn(entry))
      end
      raise "Malformed cluster.txt:\n#{parsed}" \
        if parsed.any? { |e| e.value?(nil) }
      parsed
    end
  end
end
