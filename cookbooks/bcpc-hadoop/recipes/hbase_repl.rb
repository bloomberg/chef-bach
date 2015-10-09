#
# To enable/disable replication peers
#
if (node["bcpc"]["hadoop"]["hbase"]["repl"]["enabled"])
  bash "create_hbase_repl_peer" do
    code <<-EOH
      echo "add_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}','#{node["bcpc"]["hadoop"]["hbase"]["repl"]["target"]}'"|hbase shell
      EOH
    not_if "echo list_peers|hbase shell|grep #{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}"
  end
else
  bash "stop_repl_remove_repl_peer" do
    code <<-EOH
      echo "disable_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}'"|hbase shell
      echo "remove_peer '#{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}'"|hbase shell
      EOH
    only_if "echo list_peers|hbase shell|grep #{node["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"]}"
  end
end
