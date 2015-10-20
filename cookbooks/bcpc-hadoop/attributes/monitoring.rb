default["bcpc"]["hadoop"]["zabbix"]["history_days"] = 1
default["bcpc"]["hadoop"]["zabbix"]["trend_days"] = 15
default["bcpc"]["hadoop"]["zabbix"]["cron_check_time"] = 240
default["bcpc"]["hadoop"]["zabbix"]["mail_source"] = "zabbix.zbx_mail.sh.erb"
default["bcpc"]["hadoop"]["zabbix"]["cookbook"] = nil 

# Interval within which chef-client is expected to run
default["bcpc"]["hadoop"]["zabbix"]["chef_client_check_interval"] =
  "#{((node['chef_client']['interval'].to_i + node['chef_client']['splay'].to_i) * 2 / 60).ceil}m"

# Override Graphite/Zabbix queries/triggers here
default["bcpc"]["hadoop"]["graphite"]["basic_queries"] = {} # Basic OS/Node Queries
default["bcpc"]["hadoop"]["graphite"]["service_queries"] = {} # Service specific queries
