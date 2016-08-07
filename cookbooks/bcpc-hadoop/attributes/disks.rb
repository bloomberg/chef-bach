# Enumerate available disks and how they will be used
default[:bcpc][:hadoop][:disks].tap do |disks|
  #
  # What disks will bcpc and bcpc-hadoop feel free to blank?
  # By default, all sd* devices, excluding sda.
  #
  # On our EFI-based VM builds, it's very important to omit sdb, as
  # that is the 32 MB image containing iPXE.  (It's relatively
  # harmless to overwrite it, but it will cause graphite to fail when
  # /disk/0 fills up.)
  #
  disks[:available_disks] =
    if node[:dmi][:system][:product_name] == 'VirtualBox'
      all_drives =
        node[:block_device].keys.select{ |dd| dd =~ /sd[a-i]?[b-z]/ }
      
      # Reject all disks with fewer than a million blocks, so that we
      # do not attempt to use the iPXE image as a data disk.
      all_drives.reject do |dd|
        node[:block_device][dd].nil? ||
        node[:block_device][dd][:size].to_i < 10**6
      end
    else
      node[:block_device].keys.select{ |dd| dd =~ /sd[a-i]?[b-z]/ }
    end
  
  # Keep at least this many disks for the :disk_reserve_roles
  disks[:role_min_disk] = 2
    
  # We are reserving disks for the following
  disks[:reservation_requests] = ['graphite_disk']
  
  # Reservations will be saved here
  disks[:disk_reserve_roles] = ['BCPC-Hadoop-Head']
end
