# vim: tabstop=2:shiftwidth=2:softtabstop=2 
default['bcpc']['graphite_dbname'] = "graphite"
default['bcpc']['graphite']['relay_port'] = 2013
default['bcpc']['graphite']['web_port'] = 8888
default['bcpc']['graphite']['web_https'] = true
default['bcpc']['graphite']['log']['retention'] = 15
default['bcpc']['graphite']['data']['retention'] = 15
default['bcpc']['graphite']['timezone'] = "'America/New_York'"
default['bcpc']['graphite']['carbon_fileno_limit'] = 4096
default['bcpc']['graphite']['install_dir'] = "/opt/graphite"
default['bcpc']['graphite']['local_storage_dir'] = "/opt/graphite/storage"
default['bcpc']['graphite']['local_data_dir'] = "/opt/graphite/storage/whisper"
default['bcpc']['graphite']['local_log_dir'] = "/opt/graphite/storage/log"
# Any change to the retentions require one to either delete the related whisper 
# files or use whisper-resize.py to resize the whisper files according to the 
# new setting
default['bcpc']['graphite']['carbon']['storage'] = { 
  "carbon" => { "pattern" => "^carbon\\.", "retentions" => "60:90d" },
  "hbase" => { "pattern" => "^jmx\\.hbase_rs\\..*\\.hb_regions\\.RegionServer\\.", "retentions" => "15s:1d,1m:7d" },
  "chef" => { "pattern" => "^chef\\.", "retentions" => "60:30d" },
  "default" => { "pattern" => ".*", "retentions" => "15s:7d,1m:30d,5m:90d" }
}
default['bcpc']['graphite']['django']['version'] = "1.5.4" 
default['bcpc']['graphite']['carbon']['relay']['idle_timeout'] = 1800 
default['bcpc']['graphite']['carbon']['cache']['MAX_UPDATES_PER_SECOND'] = 170 
default['bcpc']['graphite']['carbon']['relay']['use_whitelist'] = false
default['bcpc']['graphite']['carbon']['relay']['blacklist'] = []

default[:bcpc][:graphite][:ip] = node[:bcpc][:management][:vip]
