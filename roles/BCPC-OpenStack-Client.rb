require 'rubygems'
require 'ohai'
o = Ohai::System.new
o.all_plugins

ifs = o["network"]["interfaces"].keys
ips = ifs.map{|i| o["network"]["interfaces"][i]["addresses"]}.reduce({}, :merge)
# should result in a data structure akin to:
# ["10.0.100.41", {"family"=>"inet", "prefixlen"=>"20", "netmask"=>"255.255.240.0", "broadcast"=>"10.0.111.255", "scope"=>"Global"}]
ip = ips.select {|ip,v| v['family'] == "inet" and v['scope'] == "Global"}.first

name "BCPC-OpenStack-Client"
description "Role for BCPC Cluster Machines Running on OpenStack"
override_attributes "bcpc" => {
      "domain_name" => o["domain"],
      "management" => {
        "vip" => false,
        "interface" => "eth0",
        "netmask" => ip[1]["netmask"],
        "cidr" => "#{(IPAddr.new "#{ip[0]}/#{ip[1]["prefixlen"]}").to_range().first.to_string()}/#{ip[1]["prefixlen"]}",
        "gateway" => o["network"]["default_gateway"]
      },
      "storage" => {
        "interface" => "eth0",
        "netmask" => ip[1]["netmask"],
        "cidr" => "#{(IPAddr.new "#{ip[0]}/#{ip[1]["prefixlen"]}").to_range().first.to_string()}/#{ip[1]["prefixlen"]}",
        "gateway" => o["network"]["default_gateway"]
      },
      "floating" => {
        "vip" => false,
        "interface" => "eth0",
        "netmask" => ip[1]["netmask"],
        "cidr" => "#{(IPAddr.new "#{ip[0]}/#{ip[1]["prefixlen"]}").to_range().first.to_string()}/#{ip[1]["prefixlen"]}",
        "gateway" => o["network"]["default_gateway"]
      },
      "bootstrap" => {
        "admin_users" => [],
        "admin" => {
          "user" => "ubuntu",
          "group" => "ubuntu"
        }
      },
      "dns_servers" => [ o["network"]["default_gateway"] ],
      "ntp_servers" => [ o["network"]["default_gateway"] ]
    },
    "chef_client" => {
      "server_url" => "http://#{ip[0]}:4000"
    }
