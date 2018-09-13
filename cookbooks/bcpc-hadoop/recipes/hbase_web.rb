directory "#{node['bcpc']['bach_web']['document_root']}/files/hbase" do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

template "#{node['bcpc']['bach_web']['document_root']}/files/hbase/blacklist.conf" do
  source 'regexlist.conf.erb'
  user 'root'
  mode 0o0644
  variables(
    regex_list: node['bcpc']['bach_web']['conn_lib']['hbase_conn_lib_blacklist']
  )
end
