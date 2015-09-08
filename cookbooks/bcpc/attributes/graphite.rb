default['bcpc']['graphite_dbname'] = "graphite"
default['bcpc']['graphite']['relay_port'] = 2013
default['bcpc']['graphite']['web_port'] = 8888
default['bcpc']['graphite']['log']['retention'] = 15
default['bcpc']['graphite']['data']['retention'] = 15
default['bcpc']['graphite']['timezone'] = "'America/New_York'"
default['bcpc']['graphite']['carbon_fileno_limit'] = 4096
default['bcpc']['graphite']['local_data_dir'] = "/opt/graphite/storage/whisper"
default['bcpc']['graphite']['local_log_dir'] = "/opt/graphite/storage/log"
default['bcpc']['graphite']['carbon']['storage'] = { 
  "carbon"=>{ "pattern" => "^carbon\\.", "retentions"=>"60:90d" },
  "default"=>{ "pattern" =>".*", "retentions" => "15s:7d,1m:30d,5m:90d" },
  "hbase"=>{ "pattern" => "^jmx\\.hbase_rs\\.*\\.hb*\\.", "retentions" => "15s:15d" } 
}
