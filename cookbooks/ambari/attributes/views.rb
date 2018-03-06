# ambari Views Attributes

node.default['ambari']['ambari_views_props'] = {

FILES_1_0_0: {
  url: "FILES/versions/1.0.0/instances/FILES_NEW_INSTANCE", \
  data: {
  ViewInstanceInfo: { description: "Files API", label: "Files View",\
    properties: {
      "webhdfs.client.failover.proxy.provider" => "%{node['ambari']['webhdfs.client.failover.proxy.provider']}",
      "webhdfs.ha.namenode.http-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
      "webhdfs.ha.namenode.http-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
      "webhdfs.ha.namenode.https-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
      "webhdfs.ha.namenode.https-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
      "webhdfs.ha.namenode.rpc-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
      "webhdfs.ha.namenode.rpc-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
      "webhdfs.ha.namenodes.list" => "%{node['ambari']['webhdfs.ha.namenodes.list']}",
      "webhdfs.nameservices" => "%{node['ambari']['webhdfs.nameservices']}",
      "webhdfs.url" => "%{node['ambari']['webhdfs.url']}",
      "webhdfs.auth" => "%{node['ambari']['webhdfs.auth']}"
      }
    }
  }
},

HIVE_2_0_0: {
  url: "HIVE/versions/2.0.0/instances/HIVE_NEW_INSTANCE",
  data: {
  ViewInstanceInfo:  {description: "Hive View", label: "Hive View",
      properties: {
      "webhdfs.client.failover.proxy.provider" => "%{node['ambari']['webhdfs.client.failover.proxy.provider']}",
      "webhdfs.ha.namenode.http-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
      "webhdfs.ha.namenode.http-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
      "webhdfs.ha.namenode.https-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
      "webhdfs.ha.namenode.https-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
      "webhdfs.ha.namenode.rpc-address.nn1" => "%{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
      "webhdfs.ha.namenode.rpc-address.nn2" => "%{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
      "webhdfs.ha.namenodes.list" => "%{node['ambari']['webhdfs.ha.namenodes.list']}",
      "webhdfs.nameservices" => "%{node['ambari']['webhdfs.nameservices']}",
      "webhdfs.url" => "%{node['ambari']['webhdfs.url']}",
      "webhdfs.auth" => "%{node['ambari']['webhdfs.auth']}",
      "hive.jdbc.url" => "%{node['ambari']['hive.jdbc.url']}",
      "yarn.ats.url" => "%{node['ambari']['yarn.ats.url']}",
      "yarn.resourcemanager.url" => "%{node['ambari']['yarn.resourcemanager.url']}"
      }
    }
  }
}
}
