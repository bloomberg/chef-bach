#
# node.run_state[:bcpc_hadoop_disks] is for values we generate at
# runtime, by inspecting the state of the system.  These cannot be
# overridden without changing the code.
#
# That run_state is generated in bcpc-hadoop::disks
#
# node[:bcpc][:hadoop][:disks] is for static attributes that we
# know in advance.  These are easily overridden in an environment.
#
# This file contains the static attributes.
#
default[:bcpc][:hadoop][:disks].tap do |disks|
  # Keep at least this many disks for the :disk_reserve_roles
  disks[:role_min_disk] = 2

  # We are reserving disks for the following
  disks[:reservation_requests] = ['graphite_disk', 'zookeeper_disk']

  # Reservations will be saved here
  disks[:disk_reserve_roles] = ['BCPC-Hadoop-Head']
end
