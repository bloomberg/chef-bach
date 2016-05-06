# Setup HDFSDU config

set_hosts

@rm_hosts = node[:bcpc][:hadoop][:rm_hosts]
if defined?@rm_hosts and not @rm_hosts.empty? then
   node.override[:hdfsdu][:jobtracker] = "#{float_host(@rm_hosts.first[:hostname])}:8032" 
end

node.override[:hdfsdu][:namenode] = node['bcpc']['hadoop']['hdfs_url']

@oozie_hosts = node[:bcpc][:hadoop][:oozie_hosts]
if defined?@oozie_hosts and not @oozie_hosts.empty? then
   node.override[:hdfsdu][:oozie_url] = "http://#{float_host(@oozie_hosts.first[:hostname])}:11000/oozie"
end

node.override[:hdfsdu][:oozie_frequency] = 120
node.override[:hdfsdu][:oozie_timezone] = "EST"
node.override[:hdfsdu][:oozie_start_time] = %x[date -u "+%Y-%m-%dT%H:00Z"].strip 
# Set endtime to one week from now
node.override[:hdfsdu][:oozie_end_time] = %x[date -d "+7days" -u "+%Y-%m-%dT%H:00Z"].strip
