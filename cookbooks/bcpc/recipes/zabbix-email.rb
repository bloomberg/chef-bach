package 'sendemail'

node.default['bcpc']['hadoop']['zabbix']['mail_source'] = 'zabbix.zbx_email.sh.erb'
node.default['bcpc']['zabbix']['scripts']['mail'] = '/usr/local/bin/zbx_email.sh'
