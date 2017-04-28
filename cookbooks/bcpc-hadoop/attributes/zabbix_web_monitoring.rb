# the global vip end points are URLs that bond to the global virtual IP
default[:bcpc][:hadoop][:zabbix][:web_monitoring][:global_vip_endpoints] = [

  # graphite web UI
  {
    name: 'graphite_web_ui',
    url: "https://#{node[:bcpc][:management][:vip]}:#{node[:bcpc][:graphite][:web_port]}",
    description: 'Graphite web UI',
    trigger_item: 'web.test.fail', # 0 = OK, 1 = Failure
    trigger_func: 'max(10m)',
    trigger_cond: '>0',
    severity: 2, # 1 to 5, 5 is the highest
    enabled: true
  },

  # zabbix web UI
  {
    name: 'zabbix_web_ui',
    url: "https://#{node[:bcpc][:management][:vip]}:#{node[:bcpc][:zabbix][:web_port]}/dashboard.php",
    description: 'Zabbix web UI',
    trigger_item: 'web.test.fail', # 0 = OK, 1 = Failure
    trigger_func: 'max(10m)',
    trigger_cond: '>0',
    severity: 2, # 1 to 5, 5 is the highest
    enabled: true
  }
]

# the role based end points are URLs that bond to hosts with certain roles
default[:bcpc][:hadoop][:zabbix][:web_monitoring][:role_based_endpoints] = [
  {
    role: 'BCPC-Hadoop-Head-Namenode',
    end_points: [
      {
        name: 'namenode_web_ui',
        port: '50070',
        description: 'Namenode web UI',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 3, # 1 to 5, 5 is the highest
        enabled: true
      }
    ]
  },

  {
    role: 'BCPC-Hadoop-Head-Namenode-Standby',
    end_points: [
      {
        name: 'namenode_standby_web_ui',
        port: '50070',
        description: 'Namenode_standby web UI',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 3, # 1 to 5, 5 is the highest
        enabled: true
      }
    ]
  },

  {
    role: 'BCPC-Hadoop-Head-HBase',
    end_points: [
      {
        name: 'hbase_web_ui',
        port: '16010',
        description: 'HBase web UI',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 3, # 1 to 5, 5 is the highest
        enabled: true
      }
    ]
  },

  {
    role: 'BCPC-Hadoop-Worker',
    end_points: [
      {
        name: 'datanode_web_ui',
        port: '1006',
        description: 'Datanode web UI',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 2, # 1 to 5, 5 is the highest
        enabled: true
      },

      {
        name: 'yarn_app_log',
        port: '45454',
        description: 'Yarn Application Log',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 2, # 1 to 5, 5 is the highest
        enabled: true
      },

      {
        name: 'hbase_region_server_web_ui',
        port: '60300',
        description: 'HBase region server web UI',
        trigger_item: 'web.test.fail',
        trigger_func: 'max(10m)',
        trigger_cond: '>0',
        severity: 2, # 1 to 5, 5 is the highest
        enabled: true
      }
    ]
  }
]
