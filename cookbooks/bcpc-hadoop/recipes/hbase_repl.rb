#
# To enable/disable replication peers
#
if (node["bcpc"]["hadoop"]["hbase"]["repl"]["enabled"])
  bash "create_hbase_repl_peer" do
    code <<-EOH
      echo "add_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}','#{node["bcpc"]["hadoop"]["hbase"]["repl"]["target"]}'"|hbase shell
      EOH
    not_if "echo list_peers|hbase shell|grep #{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}"
    user 'hbase'
  end
else
  bash "stop_repl_remove_repl_peer" do
    code <<-EOH
      echo "disable_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}'"|hbase shell
      echo "remove_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}'"|hbase shell
      EOH
    only_if "echo list_peers|hbase shell|grep #{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}"
    user 'hbase'
  end
end

#
# To disable region replication peer
#
if (node['bcpc']['hadoop']['hbase']['site_xml']['hbase.region.replica.replication.enabled'])
  bash "enable_hbase_region_repl_peer" do
    code <<-EOH
      echo "enable_peer 'region_replica_replication'"|hbase shell
      EOH
    only_if "echo list_peers|hbase shell|grep region_replica_replication|grep DISABLED"
    user 'hbase'
  end
else
  bash "disable_hbase_region_repl_peer" do
    code <<-EOH
      echo "disable_peer 'region_replica_replication'"|hbase shell
      EOH
    not_if "echo list_peers|hbase shell|grep region_replica_replication|grep ENABLED"
    user 'hbase'
  end
end
