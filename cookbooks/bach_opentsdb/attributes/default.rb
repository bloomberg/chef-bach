#######################
# OpenTSDB attributes #
#######################

### Configuration file
default['bach_opentsdb']['network']['port'] = 4242
default['bach_opentsdb']['network']['bind'] = nil
default['bach_opentsdb']['network']['tcp_no_delay'] = 'true'
default['bach_opentsdb']['network']['keep_alive'] = 'true'
default['bach_opentsdb']['network']['reuse_address'] = 'true'
default['bach_opentsdb']['network']['worker_threads'] = nil
default['bach_opentsdb']['network']['async_io'] = 'true'
default['bach_opentsdb']['http']['staticroot'] = '/usr/share/opentsdb/static/'
default['bach_opentsdb']['http']['cachedir'] = '/tmp/opentsdb'
default['bach_opentsdb']['core']['auto_create_metrics'] = 'false'
default['bach_opentsdb']['core']['plugin_path'] = '/usr/share/opentsdb/plugins'
default['bach_opentsdb']['storage']['enable_compaction'] = 'true'
default['bach_opentsdb']['storage']['flush_interval'] = 1000
default['bach_opentsdb']['storage']['hbase']['data_table'] = 'tsdb'
default['bach_opentsdb']['storage']['hbase']['uid_table'] = 'tsdb-uid'
default['bach_opentsdb']['storage']['hbase']['zk_basedir'] = '/hbase'

### Service management/JVM parameters
default['bach_opentsdb']['tsd_user'] = 'hbase'
default['bach_opentsdb']['tsd_group'] = 'hbase'
default['bach_opentsdb']['daemon_opts'] = nil
default['bach_opentsdb']['max_open_files'] = nil
default['bach_opentsdb']['config_directory'] = '/etc/opentsdb'
default['bach_opentsdb']['bin_directory'] = '/usr/share/opentsdb/bin'
default['bach_opentsdb']['jaas_config_file'] = node['bach_opentsdb']['config_directory'] + '/opentsdb.jaas'

### Logback configuration
default['bach_opentsdb']['log_directory'] = '/var/log/opentsdb'
default['bach_opentsdb']['query_log_enable'] = false
