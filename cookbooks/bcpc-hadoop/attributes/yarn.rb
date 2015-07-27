# Yarn Node Manager configurations
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["ratio"] = 0.8
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["size"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["ratio"] = 0.8
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["count"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["xmx"]["max_size"] = 4096
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["xmx"]["max_ratio"] = 0.125

# Yarn Resourcemanager configuration
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["class"] = "org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["minimum-allocation-mb"] = 256
default["bcpc"]["hadoop"]["yarn"]["rm_port"] = 8032
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["xmx"]["max_size"] = 4096
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["xmx"]["max_ratio"] = 0.125

# Yarn History Server configuration
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["size"] = 128
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["ratio"] = 0
