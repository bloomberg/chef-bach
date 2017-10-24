#
# Cookbook Name:: bach_repository
# Recipe:: ipxe
#
# Copyright 2016, Bloomberg Finance L.P.
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
# This recipe builds a bootable ipxe USB from source, suitable for use in
# Virtualbox EFI.  This is useful for testing BACH clusters.
#

require 'tempfile'
require 'tmpdir'

# The ugly rescues are for use with chef-apply.
src_dir =
  node['bach']['repository']['src_directory'] rescue '/tmp'

bins_dir =
  node['bach']['repository']['bins_directory'] rescue '/tmp'

ipxe_src_path = File.join(src_dir, 'ipxe')

git ipxe_src_path do
  repository 'https://git.ipxe.org/ipxe.git'
  # From the iPXE FAQ:
  #
  # "iPXE uses a rolling release model, in which every commit is
  # intended to be production-ready. You should always use the latest
  # code."
  #
  # In other words, there is no release process or version attached to
  # iPXE.  So we just grab the latest commit.
  depth 1
  action :export
end

execute 'make bin-x86_64-efi/ipxe.efi' do
  cwd File.join(ipxe_src_path, 'src')
  umask 0022
  timeout 3600
end

# Initialize a blank device
disk_image_path = File.join(bins_dir, 'ipxe_raw_disk.img')
execute "dd if=/dev/zero of='#{disk_image_path}' bs=1M count=0 seek=32" do
  umask 0022
  not_if "file '#{disk_image_path}' | grep DOS.MBR"
end

execute 'modprobe -r loop && modprobe loop max_part=63' do
  not_if 'losetup /dev/loop0'
end

execute "losetup /dev/loop0 '#{disk_image_path}'" do
  not_if 'losetup /dev/loop0'
end

partition_table_path = Tempfile.new('bach_efi_usb_partitions_').path

file partition_table_path do
  content <<-EOM.gsub(/^ {4}/,'')
    unit: sectors
    
    /dev/loop0p1 : start=     2048, size=    30720, Id= b
    /dev/loop0p2 : start=        0, size=        0, Id= 0
    /dev/loop0p3 : start=        0, size=        0, Id= 0
    /dev/loop0p4 : start=        0, size=        0, Id= 0
  EOM
  mode 0444
end

execute "sfdisk /dev/loop0 < '#{partition_table_path}'" do
  notifies :delete, "file[#{partition_table_path}]"
end

execute 'partprobe /dev/loop0'

execute 'mkfs -t vfat /dev/loop0p1' do
  # 0xEB3C90 is an x86 JMP instruction, found at the beginning of a vFAT fs.
  not_if { File.binread('/dev/loop0p1', 3).unpack('H*').first == 'eb3c90' }
end

mount_path = Dir.mktmpdir('bach_efi_usb_')

mount 'bach_efi_usb' do
  device '/dev/loop0p1'
  mount_point mount_path
end

# Source
ipxe_bin_path = File.join(ipxe_src_path, 'src', 'bin-x86_64-efi', 'ipxe.efi')

# Target
efi_bin_path = File.join(mount_path, 'EFI', 'BOOT', 'bootx64.efi')

directory File.dirname(efi_bin_path) do
  action :create
  recursive true
end

execute "cp '#{ipxe_bin_path}' '#{efi_bin_path}'" do
  notifies :umount, 'mount[bach_efi_usb]', :immediately
  notifies :delete, "directory[#{mount_path}]"
end

directory mount_path do
  action :nothing
end

gpt_mbr_path = Tempfile.new('bach_gpt_mbr_').path

# This is an actual GPT boot sector from the Debian 8 SYSLINUX package.
gpt_mbr_string =
  '33c0fa8ed88ed0bc007c89e606578ec0fbfcbf00' \
  '06b90001f3a5ea1f0600005289e583ec1c6a1ec7' \
  '46fa000252b441bbaa5531c930f6f9cd135ab408' \
  '721781fb55aa7511d1e9730d66c7065907b442eb' \
  '13b44889e6cd1383e13f510fb6c640f7e1525066' \
  '31c0669940e8dc008b4e568b465a5051f7e1f776' \
  'fa9141668b464e668b565253e8c400e2fb31f65f' \
  '5958668b15660b5504660b5508660b550c740cf6' \
  '453004740621f6751989fe01c7e2df21f6752ee8' \
  'e1004d697373696e67204f530d0ae8d2004d756c' \
  '7469706c65206163746976652070617274697469' \
  '6f6e730d0a91bfbe07576631c0b08066abb0ed66' \
  'ab668b4420668b5424e84000668b4428668b542c' \
  '662b4420661b5424e87000e82a00660fb7c166ab' \
  'f3a45e668b4434668b5438e82200813efe7d55aa' \
  '758589ec5a5f0766b821475054faffe46621d274' \
  '046683c8ff66abc3bb007c66606652665006536a' \
  '016a1089e666f776dcc0e40688e188c592f676e0' \
  '88c608e141b801028a5600cd138d64106661720c' \
  '027efb6683c0016683d200c3e80c004469736b20' \
  '6572726f720d0a5eacb40e8a3e6204b307cd103c' \
  '0a75f1cd18f4ebfd000000000000000000000000' 

file gpt_mbr_path do
  content [gpt_mbr_string].pack('H*')
  mode 0444
end

execute "dd if='#{gpt_mbr_path}' of=/dev/loop0"

execute 'losetup -d /dev/loop0'
