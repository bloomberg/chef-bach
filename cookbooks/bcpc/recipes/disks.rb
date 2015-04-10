package "xfsprogs" do
  action :install
end

directory node[:bcpc][:storage][:disks][:mount_root] do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

ruby_block "mount and create disks" do
  block do
    if node["bcpc"]["storage"]["disks"]["devices"].length > 0 then
      node["bcpc"]["storage"]["disks"]["devices"].each_index do |i|
        dir = Chef::Resource::Directory.new("#{node["bcpc"]["storage"]["disks"]["mount_root"]}/#{i}", run_context)
        dir.owner "root"
        dir.group "root"
        dir.mode 00755
        dir.recursive true
        dir.run_action :create
 
        d = node[:bcpc][:storage][:disks][:devices][i]
        fs_type = node["bcpc"]["storage"]["fs"]["type"] 
        fs = Chef::Resource::Execute.new("mkfs -t #{fs_type} #{node["bcpc"]["storage"]["fs"]["mkfs_options"]} /dev/#{d}", run_context)
        fs.not_if(command="file -s /dev/#{d} | grep -q '#{node["bcpc"]["storage"]["fs"]["fstyp_string"][fs_type]}'")
        fs.run_action :run

        mount = Chef::Resource::Mount.new("#{node["bcpc"]["storage"]["disks"]["mount_root"]}/#{i}", run_context)
        mount.device "/dev/#{d}"
        mount.fstype fs_type
        mount.options node["bcpc"]["storage"]["fs"]["mount_options"]
        mount.run_action :enable
        mount.run_action :mount
      end
      node.set[:bcpc][:storage][:mounts] = (0..node[:bcpc][:storage][:disks][:devices].length-1).to_a
    else
      Chef::Application.fatal!('Please specify some node[:bcpc][:storage][:disks][:devices]!')
    end
  end
end
