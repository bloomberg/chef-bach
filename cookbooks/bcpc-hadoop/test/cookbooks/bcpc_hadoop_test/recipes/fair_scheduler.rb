# Configure scheduler configuration XML files
Chef::Resource::File.send(:include, Bcpc_Hadoop::Hadoop_Helpers)

fair_share_queue "default" do
  preemption_tout = node['bcpc']['hadoop']['yarn']['fairsharepreemptiontimeout']
  min_mb = node["bcpc"]["hadoop"]["yarn"]["scheduler"]["minimum-allocation-mb"] * node["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["min-vcores"]
  min_cores = node["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["min-vcores"]

  attributes({'type' => 'parent'})
  weight 1.0
  fairSharePreemptionTimeout preemption_tout
  minSharePreemptionTimeout fairSharePreemptionTimeout/10
  minResources "#{min_mb}mb, #{min_cores}vcores"
  action :register
end

fair_share_queue "batch" do
  preemption_tout = node['bcpc']['hadoop']['yarn']['fairsharepreemptiontimeout'] * 10

  weight 1.0
  fairSharePreemptionTimeout preemption_tout
  parent_resource "fair_share_queue[default]"
  subscribes :register, "fair_share_queue[default]", :immediate
  action :nothing
end

fair_share_queue "interactive" do
  preemption_tout = node['bcpc']['hadoop']['yarn']['fairsharepreemptiontimeout']/10

  weight 1.0
  fairSharePreemptionTimeout preemption_tout
  minSharePreemptionTimeout preemption_tout/10
  parent_resource "fair_share_queue[batch]"
  subscribes :register, "fair_share_queue[batch]", :immediate
  action :nothing
end

file "/etc/hadoop/conf/fair-scheduler.xml" do
  content lazy {fair_scheduler_xml(node.run_state[:fair_scheduler_queue] || [],
    node[:bcpc][:hadoop][:yarn][:fairSchedulerOpts],
    node[:bcpc][:hadoop][:yarn][:queuePlacementPolicy])}
  mode 0644
end
