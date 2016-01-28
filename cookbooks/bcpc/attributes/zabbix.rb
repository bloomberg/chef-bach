default['bcpc']['zabbix']['user'] = "zabbix"
default['bcpc']['zabbix']['group'] = "adm"
default['bcpc']['zabbix']['server_port'] = 10051
default['bcpc']['zabbix']['web_port'] = 7777
default['bcpc']['zabbix']['scripts']['sender'] = "/usr/local/bin/run_zabbix_sender.sh"
default['bcpc']['zabbix']['scripts']['mail'] = "/usr/local/bin/zbx_mail.sh"
default['bcpc']['zabbix']['scripts']['query_graphite'] = "/usr/local/bin/query_graphite.py"
# Interval (in seconds) during which we expect chef-client to have run at least once
default['bcpc']['zabbix']['chef_client_check_interval'] = (node['chef_client']['interval'].to_i + node['chef_client']['splay'].to_i) * 2
# Amount of historical data to retain (in days)
default['bcpc']['zabbix']['retention_history'] = 1
default['bcpc']['zabbix']['retention_default'] = 7
