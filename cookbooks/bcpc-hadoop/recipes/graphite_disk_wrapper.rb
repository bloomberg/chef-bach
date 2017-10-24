# vim: tabstop=2:shiftwidth=2:softtabstop=2
# assign prepare a directory structure for graphite to install itself to
ruby_block 'graphite-directory-structure' do
  block do
    reservation_requests =
      node[:bcpc][:hadoop][:disks][:reservation_requests]

    if reservation_requests.include?("graphite_disk") then
      disk_index = reservation_requests.index("graphite_disk")
      graphite_dir = "/disk/#{disk_index}/graphite_disk"

      Chef::Resource::Directory.new("graphite-#{disk_index}",
                                    run_context).tap do |dd|
        dd.path graphite_dir
        dd.owner 'root'
        dd.group 'root'
        dd.recursive false
        dd.run_action(:create)
      end

      Chef::Resource::Link.new(node[:bcpc][:graphite][:install_dir],
                               run_context).tap do |ll|
        ll.to graphite_dir
        ll.link_type :symbolic
        ll.run_action(:create)
      end
    end
  end
end
