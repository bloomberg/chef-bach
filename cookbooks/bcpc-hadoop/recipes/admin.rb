# Admin databag assets needed for c-a-r hadoop

include_recipe 'bcpc::admin_base'

ruby_block 'oozie keystore databags' do
  block do
    make_config('oozie-keystore-password', secure_password)
  end
  only_if { get_config('oozie-keystore-password').nil? }
end

ruby_block 'hive password databag' do
  block do
    make_config('mysql-hive-password', secure_password)
  end
  only_if { get_config('mysql-hive-password').nil? }
end

ruby_block 'hive stats password' do
  block do
    make_config('mysql-hive-table-stats-password', secure_password)
  end
  only_if { get_config('mysql-hive-table-stats-password').nil? }
end

ruby_block 'ambari password' do
  block do
    make_config('ambari-admin-password', secure_password)
  end
  only_if { get_config('ambari-admin-password').nil? }
end
