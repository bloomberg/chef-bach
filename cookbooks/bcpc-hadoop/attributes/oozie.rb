default['bcpc']['hadoop']['oozie']['admins'] = []
default['bcpc']['hadoop']['oozie']['memory_opts'] =
  '$CATALINA_OPTS' \
  ' -Xmx2048m' \
  ' -XX:MaxPermSize=256m' \
  ' -XX:+HeapDumpOnOutOfMemoryError ' \
  ' -XX:HeapDumpPath=/var/log/oozie/heap-dump-oozie-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof' \
  ' -XX:+ExitOnOutOfMemoryError' \
  " -agentpath:#{node['bcpc-hadoop']['jvmkill']['lib_file']}"
default['bcpc']['hadoop']['oozie']['sharelib_checksum'] = nil
default['bcpc']['hadoop']['oozie_config'] = '/etc/oozie/conf'
default['bcpc']['hadoop']['oozie_data'] = '/var/lib/oozie'
default['bcpc']['hadoop']['oozie_log'] = '/var/log/oozie'
default['bcpc']['hadoop']['oozie_log_dir'] = '/var/log/oozie'
default['bcpc']['hadoop']['oozie_pid_dir'] = '/var/run/oozie'
default['bcpc']['hadoop']['oozie_catalina_home'] = '/usr/lib/bigtop-tomcat'
default['bcpc']['hadoop']['cataline_tmpdir'] = '/tmp'
default['bcpc']['hadoop']['catalina_pid'] = '/var/run/oozie/oozie.pid'
default['bcpc']['hadoop']['oozie_https_port'] = 11443
default['bcpc']['hadoop']['oozie_port'] = 11000
default['bcpc']['hadoop']['oozie']['smtp_host'] = nil
default['bcpc']['hadoop']['oozie']['smtp_port'] = 25
default['bcpc']['hadoop']['oozie']['from_email'] = "oozie@localhost.com"
default['bcpc']['hadoop']['oozie']['systemmode'] = 'NORMAL'
default['bcpc']['hadoop']['oozie']['service']['AuthorizationService']['security']['enabled'] = false
default['bcpc']['hadoop']['oozie']['service']['PurgeService']['older']['than'] = 30
default['bcpc']['hadoop']['oozie']['service']['PurgeService']['purge']['interval'] = 3_600
default['bcpc']['hadoop']['oozie']['service']['CallableQueueService']['queue']['size'] = 10_000
default['bcpc']['hadoop']['oozie']['service']['CallableQueueService']['threads'] = 10
default['bcpc']['hadoop']['oozie']['service']['CallableQueueService']['callable']['concurrency'] = 3
default['bcpc']['hadoop']['oozie']['service']['coord']['normal']['default']['timeout'] = 120
default['bcpc']['hadoop']['oozie']['db']['schema']['name'] = 'oozie'
default['bcpc']['hadoop']['oozie']['service']['JPAService']['create']['db']['schema'] = false
default['bcpc']['hadoop']['oozie']['service']['JPAService']['pool']['max']['active']['conn'] = 100
default['bcpc']['hadoop']['oozie']['authentication']['token']['validity'] = 36_000
default['bcpc']['hadoop']['oozie']['service']['ext'] =
  'org.apache.oozie.service.ZKLocksService,' \
  'org.apache.oozie.service.ZKXLogStreamingService,' \
  'org.apache.oozie.service.ZKJobsConcurrencyService,' \
  'org.apache.oozie.service.ZKUUIDService'
default['bcpc']['hadoop']['oozie']['check_action_delay'] = 90
