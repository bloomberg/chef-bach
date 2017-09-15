#
# This module holds utility methods used by vm_to_cluster.rb and Vagrantfile
# NOTE: Testing should be done with ChefDK and Vagrant rubys
#
# Most of the methods use VirtualBox or are run on the VirtualBox hypervisor
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
      # Return a hash of VM names to UUIDs for VirtualBox VMs
      #
      def virtualbox_vms()
        vm_list = Mixlib::ShellOut.new('/usr/bin/vboxmanage', 'list',
                                         'vms')
        vm_list.run_command
        unless vm_list.status.success?
          raise "VM list failed: #{vm_list.stderr}"
        end

        # parse '"vm name" {UUID}' line format and return two groups:
        # 1: the vm name; 2: the VM UUID
        line_parser = Regexp.new('^"([^"]*)" {([a-f0-9-]*)}$')

        vms = vm_list.stdout.split("\n").map do |vm_line|
          (line, vm, uuid) = line_parser.match(vm_line).to_a
          # only return vm and uuid if they parsed or
          # return original line if it failed to parse
          vm && uuid ? [vm, uuid] : [nil, vm_line]
        end

        raise "Could not parse lines: \n" +
          vms.select{ |a| a.any?(&:nil?) }.map{ |k, line| line }.join("\n") \
          if vms.any?{ |a| a.any?(&:nil?) }


        vms.to_h
      end

      #
      # Return if VM is EFI or legacy BIOS boot
      #
      def virtualbox_bios(vm_id)
        vm_lookup = Mixlib::ShellOut.new('/usr/bin/vboxmanage', 'showvminfo',
                                         '--machinereadable', vm_id)
        vm_lookup.run_command
        unless vm_lookup.status.success?
          raise "VM lookup for #{vm_id} failed: #{vm_lookup.stderr}"
        end

        vm_lookup = vm_lookup.stdout.split("\n").select \
          { |line| line.start_with?('firmware="') }

        # strip leading 'firmware="' and trailing '"'
        bios = vm_lookup.first.gsub(/^firmware="/, '').gsub(/"$/, '') \
          unless vm_lookup.empty?
      end

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

        # strip leading 'macaddress1="' and trailing '"'
        unless vm_lookup.empty?
          mac = vm_lookup.first.gsub(/^macaddress1="/, '').gsub(/"$/, '')
          mac = (0..mac.length/2 - 1).map { |x| mac.slice(x * 2, 2) }.join(':')
        end
      end
    end
  end
end
