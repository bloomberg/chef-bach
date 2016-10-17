# zabbix uses sendemail
package 'sendemail'

node['bcpc']['zabbix']['scripts']['mail'] = "/usr/local/bin/zbx_mail.sh"
