# vim: tabstop=2:shiftwidth=2:softtabstop=2 
package "xfsprogs" do
  action :install
end

reservation_requests = node[:bcpc][:hadoop][:disks][:reservation_requests]
available_disks = node[:bcpc][:hadoop][:disks][:available_disks]
role_min_disk = node[:bcpc][:hadoop][:disks][:role_min_disk]

directory "/disk" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

if available_disks.length > 0 then
  available_disks.each_index do |i|
    directory "/disk/#{i}" do
      owner "root"
      group "root"
      mode 00755
      action :create
      recursive true
    end
   
    d = available_disks[i]
    execute "mkfs -t xfs -f /dev/#{d}" do
      not_if "file -s /dev/#{d} | grep -q 'SGI XFS filesystem'"
    end
 
    mount "/disk/#{i}" do
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64,nobootwait"
      action :mount
      ignore_failure true
    end

    # disk should be mounted from above; if not, we can only assume its
    # filesystem needs help; however, xfs_repair does not give a "good"
    # (mountable) filesystem a clean bill of health in many cases so only
    # if we can not mount do we then assume the worst and truncate its log
    # and worse log truncation always seems to return non-zero too
    bash "/sbin/xfs_repair -L /dev/#{d}" do
      code "/sbin/xfs_repair -L /dev/#{d}"
      not_if "mount | grep -q '^/dev/#{d} '"
      returns [0,139]
    end

    mount "/disk/#{i} verify mount" do
      mount_point "/disk/#{i}"
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64,nobootwait"
      action [:mount,:enable]
    end

  end

  # is our role included in the list
  if not (node[:bcpc][:hadoop][:disks][:disk_reserve_roles] & node.roles).empty? then 
    # make sure we have enough disks to fulfill reservations and 
    # also normal opration of the DN and NN 
    if reservation_requests.length > available_disks.length
      Chef::Application.fatal!('Reservations exceeds available disks')
    end
    if available_disks.length - reservation_requests.length < role_min_disk 
      Chef::Application.fatal!('Minimum disk requirement not met')
    end
    mount_indexes = (0..available_disks.length-1).to_a - reservation_requests.each_index.to_a
    node.set[:bcpc][:hadoop][:mounts] = mount_indexes
  else
     node.set[:bcpc][:hadoop][:mounts] = (0..available_disks.length-1).to_a
  end
else
  Chef::Application.fatal!('Please specify some node[:bcpc][:hadoop][:disks][:available_disks]!')
end
