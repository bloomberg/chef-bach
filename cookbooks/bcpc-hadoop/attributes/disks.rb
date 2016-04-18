# enumerate available disks and how they will be used
default[:bcpc][:hadoop][:disks] = {
  :available_disks => ["sdb" , "sdc", "sdd", "sde"],
  # keep at least that many disks for the :disk_reserve_roles
  :role_min_disk => 2,
  # we are reserving disks for the following
  :reservation_requests => ["graphite_disk"],
  # reservations will be saved here
  :disk_reserve_roles => ["BCPC-Hadoop-Head"]
} 
