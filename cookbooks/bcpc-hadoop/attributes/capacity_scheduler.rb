default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"].tap do |capacity|
  capacity["maximum-applications"] = 10000
  capacity["maximum-am-resource-percent"] = 0.1
  capacity["resource-calculator"] =
    "org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator"
  capacity["root"]["queues"] = "default"
  capacity["root"]["default"]["capacity"] = 100
  capacity["root"]["default"]["user-limit-factor"] = 1
  capacity["root"]["default"]["maximum-capacity"] = 100
  capacity["root"]["default"]["state"] = "RUNNING"
  capacity["root"]["default"]["acl_submit_applications"] = "*"
  capacity["root"]["default"]["acl_administer_queue"] = "*"
  capacity["node-locality-delay"] = -1
end

capacity = node[:bcpc][:hadoop][:yarn][:scheduler][:capacity]

default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["xml"].tap do |xml|
  xml['yarn.scheduler.capacity.maximum-applications'] =
    capacity["maximum-applications"]
  
  xml["yarn.scheduler.capacity.maximum-am-resource-percent"] =
    capacity['maximum-am-resource-percent']
  
  xml["yarn.scheduler.capacity.resource-calculator"] =
    capacity['resource-calculator']

  xml["yarn.scheduler.capacity.root.queues"] =
    capacity['root']['queues']
  
  xml["yarn.scheduler.capacity.root.default.capacity"] =
    capacity['root']['default']['capacity']
  
  xml["yarn.scheduler.capacity.root.default.user-limit-factor"] =
    capacity['root']['default']['user-limit-factor']
  
  xml["yarn.scheduler.capacity.root.default.maximum-capacity"] =
    capacity['root']['default']['maximum-capacity']
  
  xml["yarn.scheduler.capacity.root.default.state"] =
    capacity['root']['default']['state']
  
  xml["yarn.scheduler.capacity.root.default.acl_submit_applications"] =
    capacity['root']['default']['acl_submit_applications']
  
  xml["yarn.scheduler.capacity.root.default.acl_administer_queue"] =
    capacity['root']['default']['acl_administer_queue']
  
  xml["yarn.scheduler.capacity.node-locality-delay"] =
    capacity['node-locality-delay']
end

