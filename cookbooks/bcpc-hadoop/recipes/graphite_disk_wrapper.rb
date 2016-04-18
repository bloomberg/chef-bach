# vim: tabstop=2:shiftwidth=2:softtabstop=2 
# assign prepare a directory structure for graphite to install itself to
reservation_requests = node[:bcpc][:hadoop][:disks][:reservation_requests]

if reservation_requests.include?("graphite_disk") then
  disk_index = reservation_requests.index("graphite_disk")

  directory "/disk/#{disk_index}/graphite_disk" do
    owner "root"
    group "root"
    recursive false
  end

  link node[:bcpc][:graphite][:install_dir] do
    to "/disk/#{disk_index}/graphite_disk"
    link_type :symbolic
  end
end

