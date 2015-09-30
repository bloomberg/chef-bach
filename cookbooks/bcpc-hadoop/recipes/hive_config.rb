#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_config
# Description : To setup hive configuration only. No hive package will be installed through this Recipe
#

# check and create the data bag "hadoop"
create_databag("hadoop")

#Create hive password with back compatiblity
mysql_hive_password = get_config("mysql-hive-password")
if mysql_hive_password.nil?
  mysql_hive_password = secure_password
end

bootstrap = get_all_nodes.select{|s| s.hostname.include? 'bootstrap'}[0].fqdn
results = get_nodes_for("hive_config").map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

chef_vault_secret "mysql-hive" do
  data_bag 'hadoop'
  raw_data({ 'password' => mysql_hive_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)
  
%w{hive webhcat hcat hive-hcatalog}.each do |w|
  directory "/etc/#{w}/conf.#{node.chef_environment}" do
    owner "root"
    group "root"
    mode 00755
    action :create
    recursive true
  end

  bash "update-#{w}-conf-alternatives" do
    code %Q{
      update-alternatives --install /etc/#{w}/conf #{w}-conf /etc/#{w}/conf.#{node.chef_environment} 50
      update-alternatives --set #{w}-conf /etc/#{w}/conf.#{node.chef_environment}
    }
  end
end

ruby_block "setup-credential-provider" do
  block do
    require 'pty'
    require 'expect'
    command = "hadoop credential create javax.jdo.option.ConnectionPassword -provider jceks://file/etc/hive/conf.#{node.chef_environment}/hive.jceks"
    promt1 = "Enter password:"
    promt2 = "Enter password again:"
    password = get_config('password','mysql-hive','hadoop')
    begin
      r, w, pid = PTY.spawn(command)
      puts r.expect(promt1)
      sleep(0.5)
      w.puts(password)
      puts r.expect(promt2)
      sleep(0.5)
      w.puts(password)
      $?.exitstatus
      Process.wait(pid)
    rescue PTY::ChildExited => e
      $stderr.puts "The child process #{e} exited! #{$!.status.exitstatus}"
    end
  end
  action :run
end

file "/etc/hive/conf.#{node.chef_environment}/hive.jceks" do
  mode '0700'
  owner 'hive'
  group 'hive'
end

# Set up hive configs
%w{hive-exec-log4j.properties
   hive-log4j.properties
   hive-env.sh
   hive-site.xml }.each do |t|
   template "/etc/hive/conf/#{t}" do
     source "hv_#{t}.erb"
     if "#{t}".end_with? ".sh"
       mode 0755
     else
       mode 0644
     end
     variables(:mysql_hosts => node[:bcpc][:hadoop][:mysql_hosts].map{ |m| m[:hostname] },
               :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
               :hive_hosts => node[:bcpc][:hadoop][:hive_hosts])
  end
end

link "/etc/hive-hcatalog/conf.#{node.chef_environment}/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end
