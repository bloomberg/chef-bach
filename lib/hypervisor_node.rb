#
# This module holds utility methods shared between repxe_host.rb and
# cluster_assign_roles.rb.
#
# Most of the methods pertain to cluster.txt and its contents.  A few
# will attempt to contact the chef server.  These should probably be
# separated from each other.
#
require 'json'

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
  Hashie.logger = Logger.new(nil)
rescue LoadError
end

module BACH
  #
  # Methods to get data about a BACH cluster
  #
  module ClusterData

    #
    # Methods which only run on the hypervisor host
    #
    module HypervisorNode

      #
      # Return the first MAC address for a VirtualBox VM given the
      # VM Name (or UUID) as a string
      #
      def virtualbox_mac(vm_id)
        vm_lookup = Mixlib::ShellOut.new('/usr/bin/vboxmanage', 'showvminfo',
                                         '--machinereadable', vm_id)
        vm_lookup.run_command
        unless vm_lookup.status.success?
          raise "VM lookup for #{vm_id} failed: #{vm_lookup.stderr}"
        end

        vm_lookup = vm_lookup.stdout.split("\n").select \
          { |line| line.start_with?('macaddress1="') }

        vm_lookup.first.gsub(/^macaddress1="/, '').gsub(/"$/, '') \
          unless vm_lookup.empty?
      end
    end
  end
end
