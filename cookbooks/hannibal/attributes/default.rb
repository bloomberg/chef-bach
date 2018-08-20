##################################
#  Hannibal specific attributes  #
##################################
default['hannibal']['local_tarball'] = true
default['hannibal']['working_dir'] = '/var/run/hannibal'
default['hannibal']['ha']['role'] = 'active'
default['hannibal']['max_memory'] = '256M'
default['hannibal']['apply_evolutions'] = 'true'
default['hannibal']['app_secret_key'] = 'tempappsecretkey'
default['hannibal']['metrics']['clean_threshold'] = 86400
default['hannibal']['metrics']['default_range'] = 86400
default['hannibal']['metrics']['clean_interval'] = 43200
default['hannibal']['metrics']['regions_fetch_interval'] = 900
default['hannibal']['metrics']['logfile_fetch_interval'] = 1200
default['hannibal']['logfile']['initial_lookbehind_size'] = 1024
default['hannibal']['logfile']['set_loglevel_on_start'] = 'false'
default['hannibal']['logfile']['url_pattern'] = \
  '"http://%hostname%:%infoport%/logLevel?log=org.apache.hadoop.hbase&level=INFO"'
default['hannibal']['logfile']['path_pattern'] = \
  '"(?i)\"/logs/(.*regionserver.*[.].*)\""'
default['hannibal']['logfile']['date_format'] = '"yyyy-MM-dd HH:mm:ss,SSS"'
default['hannibal']['logfile']['fetch_timeout'] = 120
default['hannibal']['akka']['loglevel'] = '"INFO"'

# Hannibal deployment configurations
default['hannibal']['hbase_version'] = '1.1.3'
default['hannibal']['install_dir'] = '/usr/lib'
default['hannibal']['service_dir'] = '/etc/init'
default['hannibal']['log_dir'] = '/var/log/hannibal'
default['hannibal']['data_dir'] = '/var/lib/hannibal/data'
default['hannibal']['user'] = 'nobody'
default['hannibal']['owner'] = 'root'
default['hannibal']['group'] = 'root'
default['hannibal']['file_mode'] = '0644'
default['hannibal']['exec_mode'] = '0655'
default['hannibal']['port'] = 9000
default['hannibal']['service_endpoint'] = \
  "http://localhost:#{node['hannibal']['port']}/api/heartbeat" 
default['hannibal']['service_timeout'] = 360 
default[:hannibal][:checksum]["1.1.3"] = '1756455e0f097e28034f57910870c95223ae94e4d580116ae641920931255b02'
default[:hannibal][:download_url] = 'http://10.0.101.3/'

# HBase configurations for hannibal
default['hannibal']['hbase_site'].tap do |hbsite| 
  hbsite['hbase.zookeeper.quorum'] = 'localhost'
  hbsite['hbase.zookeeper.property.clientPort'] = 2181
  hbsite['hbase.rootdir'] = '/hbase'
  hbsite['hbase.security.authentication'] = 'simple'
  hbsite['hadoop.security.authentication'] = 'simple'
  hbsite['hbase.master.kerberos.principal'] = 'hbase/_HOST@BACH.EXAMPLE.COM'
  hbsite['hbase.regionserver.kerberos.principal'] = 'hbase/_HOST@EXAMPLE.COM'
  hbsite['hannibal.kerberos.keytab'] = '/etc/security/keytabs/hannibal.service.keytab'
  hbsite['hannibal.kerberos.principal'] = 'hannibal@EXAMPLE.COM'
  hbsite['hbase.regionserver.info.port'] = 60200
end

# Hannibal DB Configurations
default['hannibal']['db'] = 'h2'
default['hannibal']['db']['user'] = "hannibal"
default['hannibal']['db']['password'] = "hannibal"
default['hannibal']['db']['driver'] = 'org.h2.Driver'
default['hannibal']['db']['url'] = \
  %Q("jdbc:h2:#{node['hannibal']['data_dir']}/metrics.h2;MODE=MYSQL")

