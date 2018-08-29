directory "#{node['bcpc']['bach_web']['document_root']}/files/hdfs" do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

template "#{node['bcpc']['bach_web']['document_root']}/files/hdfs/blacklist.conf" do
  source 'regexlist.conf.erb'
  user 'root'
  mode 0o0644
  variables(
    regex_list: node['bcpc']['bach_web']['conn_lib']['hdfs_conn_lib_blacklist']
  )
end
