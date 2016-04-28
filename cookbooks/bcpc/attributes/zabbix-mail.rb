# To enable zabbix email alarm, please override the following attributes, and change "owner" to the recipient email
node.override["bcpc"]["hadoop"]["zabbix"]["mail_source"] = "zabbix.zbx_mail.sh.erb"
node.override["bcpc"]["hadoop"]["zabbix"]["mail_from"] = "zabbix@example.com"
node.override["bcpc"]["hadoop"]["zabbix"]["mail_smtp_server_port"] = "smtp.example.com:25"
node.override['bcpc']['zabbix']['scripts']['mail'] = "/usr/local/bin/zbx_mail.sh"
