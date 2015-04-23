##################################
#  Hannibal specific attributes  #
##################################

default[:hannibal][:local_tarball] = true
default[:hannibal][:download_url] = 'https://github.com/sentric/hannibal/releases/download/v.0.10.1'
default[:hannibal][:repo][:url] = 'https://github.com/kiiranh/hannibal.git'
default[:hannibal][:repo][:branch] = 'next'
default[:hannibal][:hbase_version] = 0.98

default[:hannibal][:install_dir] = '/usr/lib'
default[:hannibal][:service_dir] = '/etc/init'
default[:hannibal][:log_dir] = '/var/log/hannibal'
default[:hannibal][:data_dir] = '/var/lib/hannibal/data'
default[:hannibal][:working_dir] = '/var/run/hannibal'
default[:hannibal][:bin_dir] = '/home/vagrant/chef-bcpc/bins'

default[:hannibal][:port] = 9000
default[:hannibal][:service_endpoint] = "http://localhost:#{node[:hannibal][:port]}/api/heartbeat" 
default[:hannibal][:service_timeout] = 360 

default[:hannibal][:user] = 'nobody'
default[:hannibal][:owner] = 'root'
default[:hannibal][:group] = 'root'
default[:hannibal][:file_mode] = '0644'
default[:hannibal][:exec_mode] = '0655'

default[:hannibal][:checksum]["0.90"] = '32183556dc5423b84655f7ef57b06ad910b2ec69f10809d359a5a813b7cb6ad2'
default[:hannibal][:checksum]["0.92"] = '9255ff08605f917018848da437465df76a54a458cc109d1d9454352d40227974'
default[:hannibal][:checksum]["0.94"] = '23ff0a640942258ffe417065713d0108a9e6d3338ec231ab08d04e1baf8ff903'
default[:hannibal][:checksum]["0.96"] = 'cc18829d8fb9cd0d3a792a609ed5fb56fcf377017ff31575b0f365ff1e119de8'
default[:hannibal][:checksum]["0.98"] = 'fd45dfc0ec3128331783aca862a21a310be7583b7f726ce3c414ee6c4d782f9d'

default[:hannibal][:ha][:role] = 'active'
default[:hannibal][:max_memory] = '256M'
default[:hannibal][:apply_evolutions] = 'true'
default[:hannibal][:app_secret_key] = 'tempappsecretkey'

default[:hannibal][:db] = 'h2'
default[:hannibal][:db_user] = "hannibal"
default[:hannibal][:db_password] = "hannibal"
default[:hannibal][:h2][:driver] = 'org.h2.Driver'
default[:hannibal][:h2][:url] = '"jdbc:h2:data/metrics.h2;MODE=MYSQL"'
default[:hannibal][:mysql][:db_name] = 'hannibal' 
default[:hannibal][:mysql][:driver] = 'com.mysql.jdbc.Driver' 
default[:hannibal][:mysql][:url] = '"jdbc:mysql://localhost/hannibal?characterEncoding=UTF-8"'

default[:hannibal][:zookeeper_quorum] = 'localhost'
default[:hannibal][:hbase_rs][:info_port] = 60030

default[:hannibal][:metrics][:clean_threshold] = 86400
default[:hannibal][:metrics][:default_range] = 86400
default[:hannibal][:metrics][:clean_interval] = 43200
default[:hannibal][:metrics][:regions_fetch_interval] = 900
default[:hannibal][:metrics][:logfile_fetch_interval] = 1200
default[:hannibal][:logfile][:initial_lookbehind_size] = 1024
default[:hannibal][:logfile][:set_loglevel_on_start] = 'false'
default[:hannibal][:logfile][:url_pattern] = '"http://%hostname%:%infoport%/logLevel?log=org.apache.hadoop.hbase&level=INFO"'
default[:hannibal][:logfile][:path_pattern] = '"(?i)\"/logs/(.*regionserver.*[.].*)\""'
default[:hannibal][:logfile][:date_format] = '"yyyy-MM-dd HH:mm:ss,SSS"'
default[:hannibal][:logfile][:fetch_timeout] = 120
default[:hannibal][:akka][:loglevel] = '"INFO"'

