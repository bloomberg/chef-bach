# Default values for zabbix items, triggers, and actions

# Item
default['bcpc']['zabbix']['item']['status'] = 0    # 0 = enabled
default['bcpc']['zabbix']['item']['type'] = 2 # 2 = Zabbix trapper (received from outside)
default['bcpc']['zabbix']['item']['data_type'] = 0 # 0 = decimal

# Trigger
default['bcpc']['zabbix']['trigger']['status'] = 0 # 0 = enabled

# Action
default['bcpc']['zabbix']['action']['status'] = 0 # 0 = enabled
default['bcpc']['zabbix']['action']['eventsource'] = 0 # 0 = event created by a trigger
default['bcpc']['zabbix']['action']['filter']['evaltype'] = 1 # 1 = AND
default['bcpc']['zabbix']['action']['filter']['conditions']['conditiontype'] = 3 # 3 = trigger name
default['bcpc']['zabbix']['action']['filter']['conditions']['operator'] = 2 # 2 = like, 0 = '='(default)
default['bcpc']['zabbix']['action']['filter']['conditions']['trigger_problem'] = {'conditiontype' => 5,'operator' => 0,'value' => 1} # trigger is in problem status
default['bcpc']['zabbix']['action']['filter']['conditions']['maintenance_off'] = {'conditiontype' => 16,'operator' => 7, 'value' => ''} # maintenance flag is off
default['bcpc']['zabbix']['action']['operations']['operationtype'] = 1 # 1 = remote command
default['bcpc']['zabbix']['action']['operations']['esc_step_from'] = 2 #
default['bcpc']['zabbix']['action']['operations']['esc_step_to'] = 2 #
default['bcpc']['zabbix']['action']['operations']['opcommand']['type'] = 0 # 0 = custom script
default['bcpc']['zabbix']['action']['operations']['opcommand']['execute_on'] = 1 # 1 - Zabbix server.
default['bcpc']['zabbix']['action']['operations']['opcommand_host']['hostid'] = 0 # 0 = current host
