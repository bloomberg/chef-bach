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

reservation_requests =
  node[:bcpc][:hadoop][:disks][:reservation_requests]

available_disks =
  node[:bcpc][:hadoop][:disks][:available_disks]

role_min_disk =
  node[:bcpc][:hadoop][:disks][:role_min_disk]

directory '/disk' do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end

if !available_disks.empty?
  available_disks.each_index do |i|
    directory "/disk/#{i}" do
      owner 'root'
      group 'root'
      mode 00755
      action :create
      recursive true
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
      execute "parted -s /dev/#{base_name} mklabel gpt" do
        not_if { ::File.exist?(dev_name) }
      end

      execute "parted -s /dev/#{base_name} mkpart bach_data ext4 0% 100%" do
        not_if { ::File.exist?(dev_name) }
      end
    end

    execute "mkfs -t xfs -f #{dev_name}" do
      not_if "file -s #{dev_name} | grep -q 'SGI XFS filesystem'"
    end

    mount "/disk/#{i}" do
      device dev_name
      fstype 'xfs'
      options 'noatime,nodiratime,inode64'
      action [:enable, :mount]
    end
  end

  # is our role included in the list
  if ! (node[:bcpc][:hadoop][:disks][:disk_reserve_roles] &
        node.roles).empty?

    # make sure we have enough disks to fulfill reservations and
    # also normal opration of the DN and NN
    if reservation_requests.length > available_disks.length
      Chef::Application.fatal!('Reservations exceeds available disks')
    end

    if available_disks.length - reservation_requests.length < role_min_disk
      Chef::Application.fatal!('Minimum disk requirement not met')
    end

    mount_indexes =
      (0..(available_disks.length - 1)).to_a -
      reservation_requests.each_index.to_a

    node.set[:bcpc][:hadoop][:mounts] = mount_indexes
  else
    node.set[:bcpc][:hadoop][:mounts] = (0..(available_disks.length - 1)).to_a
  end
else
  Chef::Application.fatal!('Please specify some ' \
                           'node[:bcpc][:hadoop][:disks][:available_disks]!')
end
