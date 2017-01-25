# vim: tabstop=2:shiftwidth=2:softtabstop=2
# assign prepare a directory structure for graphite to install itself to
ruby_block 'graphite-directory-structure' do
  block do
    reservation_requests =
      node.run_state[:bcpc_hadoop_disks][:reservation_requests]

    if reservation_requests.include?("graphite_disk") then
      disk_index = reservation_requests.index("graphite_disk")

      Chef::Resource::Directory.new("graphite-#{disk_index}").tap do |dd|
        dd.path "/disk/#{disk_index}/graphite_disk"
        dd.owner 'root'
        dd.group 'root'
        dd.recursive false
      end

      Chef::Resource::Link.new(node[:bcpc][:graphite][:install_dir]).tap do |ll|
        ll.to "/disk/#{disk_index}/graphite_disk"
        ll.link_type :symbolic
      end
    end
  end
end
