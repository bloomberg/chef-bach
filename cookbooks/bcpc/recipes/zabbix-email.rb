package 'sendemail'

node.override["bcpc"]["hadoop"]["zabbix"]["mail_source"] = "zabbix.zbx_email.sh.erb"
node.override['bcpc']['zabbix']['scripts']['mail'] = "/usr/local/bin/zbx_email.sh"
