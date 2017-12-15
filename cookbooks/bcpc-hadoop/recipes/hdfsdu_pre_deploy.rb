# Setup HDFSDU config

include_recipe 'bcpc-hadoop::hdfsdu_kerberos'

hdfsdu_keytab = ::File.join(node['bcpc']['hadoop']['kerberos']['keytab']['dir'],
  node[:bcpc]['hadoop']['kerberos']['data']['hdfsdu']['keytab'])
hdfsdu_hdfs_user = node['hdfsdu']['hdfsdu_user']

node.override[:hdfsdu][:service_download_url] = get_binary_server_url
node.override[:bcpc][:hadoop][:hdfs][:dfs][:cluster][:administrators] = \
  node[:bcpc][:hadoop][:hdfs][:dfs][:cluster][:administrators] + ',' + \
  hdfsdu_hdfs_user

configure_kerberos 'hdfsdu_keytab' do
  service_name hdfsdu_hdfs_user
end
