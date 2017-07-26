#
# Cookbook Name:: bcpc
# Disk Helpers
#
# Copyright 2017, Bloomberg Finance L.P.
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

#
# Returns node[:filesystem] with only bcpc/bcpc-hadoop mounts included.
#
# These mount targets all follow the pattern /disk/NN.
#
def bcpc_mounted_filesystems
  bcpc_ohai_reload(:filesystem)

  node[:filesystem].select do |_, fs|
    fs[:mount] =~ %r(^/disk/\d+$)
  end
end

#
# Reloads an ohai plugin on demand.
#
# Takes one argument, a name of an ohai plugin in string or symbol form.
#
# Returns nil.
#
def bcpc_ohai_reload(plugin_name)
  require 'ohai'

  ohai = ::Ohai::System.new
  ohai.all_plugins(plugin_name.to_s)

  #
  # This is not a "deep" merge.
  #
  # Subtrees under matching keys are replaced, not merged.
  #
  node.automatic_attrs.merge!(ohai.data)

  Chef::Log.info("ohai[#{plugin_name.to_s}] reloaded")

  nil
end

#
# Returns a list of block devices not currently in use by the kernel.
#
# Device names are basenames, not paths. e.g. sda, sdb, sdd
#
def bcpc_unused_disks
  bcpc_ohai_reload(:block_device)

  #
  # What disks will bcpc and bcpc-hadoop feel free to blank?
  # By default, all unused sd* and md* devices.
  #
  # On our EFI-based VM builds, it's very important to the 32 MB
  # image containing iPXE.  (It's relatively harmless to overwrite
  # it, but it will cause graphite to fail when /disk/0 fills up.)
  #
  # We also reject any block device we are unable to open with O_EXCL,
  # because that means it is already in use, presumably by the kernel.
  #
  all_drives = node[:block_device].keys.select do |dd|
    # /dev/sdiv is currently the last possible SCSI device node.
    dd =~ /sd[a-i]?[a-z]/ || dd =~ /md\d+/
  end.select do |dd|
    begin
      require 'fcntl'
      fd = IO::sysopen("/dev/#{dd}", Fcntl::O_RDONLY | Fcntl::O_EXCL)
      IO.new(fd).close
      true
    rescue Errno::EBUSY => ee
      Chef::Log.debug("Unable to open #{dd} with O_EXCL: #{ee}")
      nil
    end
  end

  if node[:dmi][:system][:product_name] == 'VirtualBox'
    #
    # On a VM build, we reject all disks with fewer than a million
    # blocks, so that we do not attempt to use the iPXE image as a
    # data disk.
    #
    all_drives.reject do |dd|
      node[:block_device][dd].nil? ||
        node[:block_device][dd][:size].to_i < 10**6
    end
  else
    all_drives
  end
end

# Returns a list of available mount targets matching the /disk/NN pattern.
def bcpc_unused_targets
  #
  # Since the kernel expects to find no more than 256 scsi devices, it
  # seems unlikely we will ever have more than 256 data volumes on a
  # single node.
  #
  # If we ever do, someone will need to update this magic value!
  #
  all_targets = (0 .. 255).to_a.map do |nn|
    "/disk/#{nn}"
  end

  targets_in_use = bcpc_mounted_filesystems.values.map do |fs|
    fs[:mount]
  end

  all_targets - targets_in_use
end

# Returns a UUID for a device, if found.
def bcpc_uuid_for_device(dev_name)
  require 'mixlib/shellout'

  blkid_command = Mixlib::ShellOut.new('blkid', dev_name)
  blkid_command.run_command

  if blkid_command.status.success?
    begin
      blkid_command.stdout.match(%r{UUID="(.*?)"})[1]
    rescue
      Chef::Log.debug("No UUID found for '#{dev_name}'")
      nil
    end
  else
    Chef::Log.warn("Failed to run blkid on '#{dev_name}'")
    nil
  end
end
