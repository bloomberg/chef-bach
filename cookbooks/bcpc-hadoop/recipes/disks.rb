package "xfsprogs" do
  action :install
end

directory "/disk" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

ruby_block "hadoop disks" do
  block do
    if node[:bcpc][:hadoop][:disks].length > 0 then
      node[:bcpc][:hadoop][:disks].each_index do |i|
        dir = Chef::Resource::Directory.new("/disk/#{i}", run_context)
        dir.owner "root"
        dir.group "root"
        dir.mode 00755
        dir.recursive true
        dir.run_action :create
   
        d = node[:bcpc][:hadoop][:disks][i]
        fs = Chef::Resource::Execute.new("mkfs -t xfs -f /dev/#{d}", run_context)
        fs.not_if(command="file -s /dev/#{d} | grep -q 'SGI XFS filesystem'")
        fs.run_action :run

        mount = Chef::Resource::Mount.new("/disk/#{i}", run_context)
        mount.device "/dev/#{d}"
        mount.fstype "xfs"
        mount.options "noatime,nodiratime,inode64"
        mount.run_action :enable
        mount.run_action :mount
      end
      node.set[:bcpc][:hadoop][:mounts] = (0..node[:bcpc][:hadoop][:disks].length-1).to_a
    else
      Chef::Application.fatal!('Please specify some node[:bcpc][:hadoop][:disks]!')
    end
  end
end
