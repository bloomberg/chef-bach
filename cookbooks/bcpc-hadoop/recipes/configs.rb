# disable IPv6 (e.g. for HADOOP-8568)
case node["platform_family"]
  when "debian"
    %w{net.ipv6.conf.all.disable_ipv6
       net.ipv6.conf.default.disable_ipv6
       net.ipv6.conf.lo.disable_ipv6}.each do |param|
      sysctl_param param do
        value 1
        notifies :run, "bash[restart_networking]", :delayed
      end
    end

    bash "restart_networking" do
      code "service networking restart"
      action :nothing
    end
  else
   Chef::Log.warn "============ Unable to disable IPv6 for non-Debian systems"
end

# set vm.swapiness to 0 (to lessen swapping)
sysctl_param 'vm.swappiness' do
  value 0
end

# Populate node attributes for all kind of hosts
set_hosts

package "bigtop-jsvc"

template "hadoop-detect-javahome" do
  path "/usr/lib/bigtop-utils/bigtop-detect-javahome"
  source "hdp_bigtop-detect-javahome.erb"
  owner "root"
  group "root"
  mode "0755"
end

%w{openjdk-7-jdk zookeeper}.each do |pkg|
  package pkg do
    action :upgrade
  end
end
