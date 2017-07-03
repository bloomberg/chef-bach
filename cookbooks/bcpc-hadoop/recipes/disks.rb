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

['xfsprogs', 'parted'].each do |package_name|
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
    node.run_state[:bcpc_hadoop_disks].tap do |disks|
      #
      # What disks will bcpc and bcpc-hadoop feel free to blank?
      # By default, all sd* devices (excluding sda) and all md* devices.
      #
      # On our EFI-based VM builds, it's very important to the 32 MB
      # image containing iPXE.  (It's relatively harmless to overwrite
      # it, but it will cause graphite to fail when /disk/0 fills up.)
      #
      # We also reject any block device we are unable to open with O_EXCL,
      # because that means it is already in use by the kernel.
      #
      all_drives = node[:block_device].keys.select do |dd|
        dd =~ /sd[a-i]?[a-z]/ || dd =~ /md\d+/
      end.select do |dd|
        begin
          require 'fcntl'
          fd = IO::sysopen("/dev/#{dd}", Fcntl::O_RDONLY | Fcntl::O_EXCL)
          fd.close
          true
        rescue Exception => ee
          Chef::Log.debug("Unable to open #{dd} with O_EXCL: #{ee}")
          nil
        end
      end

      disks[:unformatted_disks] =
        if node[:dmi][:system][:product_name] == 'VirtualBox'

          # Reject all disks with fewer than a million blocks, so that we
          # do not attempt to use the iPXE image as a data disk.
          all_drives.reject do |dd|
            node[:block_device][dd].nil? ||
              node[:block_device][dd][:size].to_i < 10**6
          end
        else
          all_drives
        end
    end
  end
end

directory '/disk' do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end

ruby_block 'format-disks' do
  block do
    #
    # Reservation requests and role_min_disks are set statically, in
    # Chef's "compile" pass.
    #
    reservation_requests =
      node[:bcpc][:hadoop][:disks][:reservation_requests]

    #
    # The available disks list is generated dynamically, at converge time.
    #
    unformatted_disks =
      node.run_state[:bcpc_hadoop_disks][:unformatted_disks]

    unformatted_disks.each_index do |i|
      Chef::Resource::Directory.new("/disk/#{i}",
                                    node.run_context).tap do |dd|
        dd.owner 'root'
        dd.group 'root'
        dd.mode 00755
        dd.recursive true
        dd.run_action(:create)
      end

      base_name = available_disks[i]

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

      Chef::Resource::Mount.new("/disk/#{i}",
                                node.run_context).tap do |mm|
        mm.device dev_name
        mm.fstype 'xfs'
        mm.options 'noatime,nodiratime,inode64'
        mm.run_action(:enable)
        mm.run_action(:mount)
      end
    end
  end
end

ruby_block 'hadoop-disk-reservations' do
  block do
    #
    # Reload Ohai filesystem plugin, in order to pick up any newly
    # formatted filesystems.
    #
    ohai = ::Ohai::System.new
    ohai.all_plugins('filesystem')
    node.automatic_attrs.merge! ohai.data
    Chef::Log.info('ohai[filesystem] reloaded')

    available_disks = node[:filesystem].select do |device, mount_point|
      # All disks formatted by this recipe were mounted at /disk/NN.
      mount_point =~ /\/disk\/\d+/
    end.keys

    # is our role included in the list
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
