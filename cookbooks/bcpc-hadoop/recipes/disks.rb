# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook Name:: bcpc-hadoop
# Recipe:: disks
#
# Copyright 2014-2016, Bloomberg Finance L.P.
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

['xfsprogs', 'parted', 'util-linux'].each do |package_name|
  package package_name do
    action :upgrade
  end
end

# Enumerate available disks and how they will be used
ruby_block 'enumerate-disks' do
  block do
    Chef::Resource::Ohai.new('reload-block-devices',
                             node.run_context).tap do |oh|
      oh.plugin 'block_device'
      oh.run_action :reload
    end

    #
    # node.run_state[:bcpc_hadoop_disks] is for values we generate at
    # runtime, by inspecting the state of the system.  These cannot be
    # overridden without changing the code.
    #
    # node[:bcpc][:hadoop][:disks] is for static attributes that we
    # know in advance.  These are easily overridden in an environment.
    #
    node.run_state[:bcpc_hadoop_disks] = {}
  end
end

directory '/disk' do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end

#
# 0. call mount -a
#
# 1. identify unused disks
#
# 2. delete any fstab entries that match un-mounted targets
#
# 3. generate a list of (device, target) tuples to be provided to the
#    otherwise-idempotent formatting + mounting process
#
# 4. use mounts data to replace any fstab lines using raw device names
#    with uuids
#

execute 'bcpc-hadoop-mount-all' do
  command '/bin/mount -a'
end

ruby_block 'purge-stale-fstab-entries' do
  block do
    require 'augeas'

    bcpc_unused_targets.each do |mount_target|
      Augeas::open do |aug|
        aug.rm("/files/etc/fstab/*[file='#{mount_target}']")

        aug.save or
          raise "Failed to remove stale #{mount_target} from /etc/fstab"
      end
    end
  end
end

ruby_block 'format-disks' do
  block do
    #
    # This is a list of tuples of unused disk names and available
    # targets to mount them at.
    #
    # The relevant helpers are defined in
    # cookbooks/bcpc/libraries/disk_helpers.rb
    #
    mounts_to_create = bcpc_unused_disks.zip(bcpc_unused_targets)

    mounts_to_create.each do |base_name, mount_target|
      Chef::Resource::Directory.new(mount_target,
                                    node.run_context).tap do |dd|
        dd.owner 'root'
        dd.group 'root'
        dd.mode 00755
        dd.recursive true
        dd.run_action(:create)
      end

      #
      # If the raw disk has already been formatted with an FS, no
      # partition table is necessary.
      #
      # Otherwise, create a partition and format that.
      #
      require 'mixlib/shellout'

      fs_check =
        Mixlib::ShellOut.new('file', '-s', "/dev/#{base_name}")
      fs_check.run_command

      dev_name = if fs_check.status.success? &&
                     fs_check.stdout.include?('SGI XFS filesystem')
                   "/dev/#{base_name}"
                 else
                   "/dev/#{base_name}1"
                 end

      if dev_name.end_with?('1')
        unless ::File.exist?(dev_name)
          Chef::Resource::Execute.new("mklabel-#{base_name}",
                                      node.run_context).tap do |ee|
            ee.command "parted -s /dev/#{base_name} mklabel gpt"
            ee.run_action(:run)
          end

          Chef::Resource::Execute.new("mkpart-#{base_name}",
                                      node.run_context).tap do |ee|
            ee.command "parted -s /dev/#{base_name} " \
              'mkpart bach_data ext4 0% 100%'
            ee.run_action(:run)
          end
        end
      end

      check_command =
        Mixlib::ShellOut.new("file -s #{dev_name} | " \
                             "grep -q 'SGI XFS filesystem'")
      check_command.run_command

      unless check_command.status.success?
        Chef::Resource::Execute.new("mkfs-#{dev_name}",
                                    node.run_context).tap do |ee|
          ee.command "mkfs -t xfs -f #{dev_name}"
          ee.run_action(:run)
        end
      end

      uuid_candidate = bcpc_uuid_for_device(dev_name)

      Chef::Resource::Mount.new(mount_target,
                                node.run_context).tap do |mm|
        if uuid_candidate
          mm.device uuid_candidate
          mm.device_type :uuid
        else
          mm.device dev_name
          mm.device_type :device
        end

        mm.fstype 'xfs'
        mm.options 'noatime,nodiratime,inode64'
        mm.run_action(:enable)
        mm.run_action(:mount)
      end
    end
  end
end

#
# This block uses augeas to update the fstab entries for any
# mounted filesystems matching the bcpc pattern (/disk/NN).
#
# The new entries, when possible, use a UUID instead of a device name.
#
ruby_block 'use-uuids-in-fstab' do
  block do
    require 'augeas'

    bcpc_mounted_filesystems.each do |dev_name, fs|
      uuid = bcpc_uuid_for_device(dev_name)

      unless uuid
        Chef::Log.warn("Cannot derive UUID for mounted fs at #{dev_name}!")
        next
      end

      uuid_device = "UUID=#{uuid}"

      Augeas::open do |aug|
        fstab_device =
          aug.get("/files/etc/fstab/*[file='#{fs[:mount]}']/spec")

        unless fstab_device.include?('UUID')
          Chef::Log.debug("Not updating fstab for #{dev_name}")
          next
        end

        aug.set("/files/etc/fstab/*[file='#{fs[:mount]}']/spec", uuid_device)

        aug.save or
          raise "Failed to update fstab with UUID for #{dev_name}"
      end
    end
  end
end

ruby_block 'hadoop-disk-reservations' do
  block do
    #
    # Reservation requests and role_min_disks are set statically, in
    # Chef's "compile" pass.
    #
    reservation_requests =
      node[:bcpc][:hadoop][:disks][:reservation_requests]

    #
    # Reload Ohai filesystem plugin, in order to pick up any newly
    # formatted filesystems.
    #
    ohai = ::Ohai::System.new
    ohai.all_plugins('filesystem')
    node.automatic_attrs.merge! ohai.data
    Chef::Log.info('ohai[filesystem] reloaded')

    # This helper is defined in cookbooks/bcpc/libraries/disk_helpers.rb
    available_disks = bcpc_mounted_filesystems.keys

    # Is this node's current role in the list?
    if (node[:bcpc][:hadoop][:disks][:disk_reserve_roles] &
        node.roles).any?
      #
      # Make sure we have enough disks to fulfill reservations and
      # also normal operations of the DN and NN.
      #
      if reservation_requests.length > available_disks.length
        raise 'Reservations exceeds available disks'
      end

      role_min_disk =
        node[:bcpc][:hadoop][:disks][:role_min_disk]

      if available_disks.length - reservation_requests.length < role_min_disk
        raise 'Minimum disk requirement not met'
      end

      mount_indexes =
        (0..(available_disks.length - 1)).to_a -
        reservation_requests.each_index.to_a

      node.run_state[:bcpc_hadoop_disks][:mounts] = mount_indexes
    else
      node.run_state[:bcpc_hadoop_disks][:mounts] =
        (0..(available_disks.length - 1)).to_a
    end
  end
end
