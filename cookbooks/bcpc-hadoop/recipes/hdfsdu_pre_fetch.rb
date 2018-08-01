# Setup HDFSDU config
require 'time'

include_recipe 'bcpc-hadoop::hdfsdu_kerberos'

hdfsdu_keytab = ::File.join(node['bcpc']['hadoop']['kerberos']['keytab']['dir'],
  node['bcpc']['hadoop']['kerberos']['data']['hdfsdu']['keytab'])
hdfsdu_hdfs_user = node['hdfsdu']['hdfsdu_user']

set_hosts

rm_hosts = node[:bcpc][:hadoop][:rm_hosts]
if defined? rm_hosts && !rm_hosts.empty?
  if rm_hosts.length > 1
    node.override[:hdfsdu][:jobtracker] = node.chef_environment
  else
    node.override[:hdfsdu][:jobtracker] = \
      "#{rm_hosts.first[:hostname]}:8032"
  end
end

node.override[:hdfsdu][:namenode] = node['bcpc']['hadoop']['hdfs_url']

oozie_hosts = node[:bcpc][:hadoop][:oozie_hosts]
if defined? oozie_hosts && !oozie_hosts.empty?
  node.override[:hdfsdu][:oozie_url] = \
    "http://#{oozie_hosts.first[:hostname]}:11000/oozie"
end

node.override[:hdfsdu][:oozie_frequency] = 120
node.override[:hdfsdu][:oozie_timezone] = 'EST'
time_now = Time.now.utc
# Oozie wants time in yyyy-MM-dd'T'HH:mm'Z' format
node.override[:hdfsdu][:oozie_start_time] = time_now.strftime("%FT%RZ")
# Set endtime to one week from now
node.override[:hdfsdu][:oozie_end_time] = (time_now + 60 * 60 * 24 * 7).strftime("%FT%RZ")

configure_kerberos 'hdfsdu_keytab' do
  service_name hdfsdu_hdfs_user
end
