#
# Recipe to include hbase jar files into Oozie
#
%w{
hbase
}.each do |p|
  package p do
    action :install
  end
end

file "/tmp/oozie.war" do
  owner 'root'
  group 'root'
  mode 0744
  content ::File.open("/usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie.war").read
  action :create
end

directory '/tmp/oozie-hbase-prep' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

bash 'extract-oozie-war' do
  user "root"
  group "root"
  code <<-EOH
    cd /tmp/oozie-hbase-prep
    jar -xf ../oozie.war
  EOH
  action :run
end

bash 'copy-hbase-jars' do
  user "root"
  group "root"
  code <<-EOH
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/hbase-common-0.98.4.2.2.0.0-2041-hadoop2.jar /tmp/oozie-hbase-prep/WEB-INF/lib/hbase-common-0.98.4.2.2.0.0-2041-hadoop2.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/hbase-client-0.98.4.2.2.0.0-2041-hadoop2.jar /tmp/oozie-hbase-prep/WEB-INF/lib/hbase-client-0.98.4.2.2.0.0-2041-hadoop2.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/hbase-server-0.98.4.2.2.0.0-2041-hadoop2.jar /tmp/oozie-hbase-prep/WEB-INF/lib/hbase-server-0.98.4.2.2.0.0-2041-hadoop2.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/hbase-protocol-0.98.4.2.2.0.0-2041-hadoop2.jar /tmp/oozie-hbase-prep/WEB-INF/lib/hbase-protocol-0.98.4.2.2.0.0-2041-hadoop2.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/hbase-hadoop2-compat-0.98.4.2.2.0.0-2041-hadoop2.jar /tmp/oozie-hbase-prep/WEB-INF/lib/hbase-hadoop2-compat-0.98.4.2.2.0.0-2041-hadoop2.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/htrace-core-*.jar /tmp/oozie-hbase-prep/WEB-INF/lib/htrace-core-*.jar
    cp /usr/hdp/2.2.0.0-2041/hbase/lib/netty-3.6.6.Final.jar /tmp/oozie-hbase-prep/WEB-INF/lib/netty-3.6.6.Final.jar
  EOH
  action :run
  not_if do ::File.exists?('/tmp/oozie-hbase-prep/WEB-INF/lib/hbase-common-0.98.4.2.2.0.0-2041-hadoop2.jar') end
  notifies :run,"bash[create-new-oozie-war]", :immediately
end

bash 'create-new-oozie-war' do
  user "root"
  group "root"
  code <<-EOH
    cd /tmp/oozie-hbase-prep
    jar -cMf ../oozie.war *
  EOH
  action :nothing
  notifies :stop,"service[stop-oozie]", :immediately
end

service "stop-oozie" do
  action :nothing
  service_name "oozie"
  supports :status => true, :restart => true, :reload => false
  notifies :run,"bash[copy-hbase-jars]", :immediately
end

bash 'copy-hbase-jars' do
  user "root"
  group "root"
  code <<-EOH
    cp /usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie.war /usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie.war.orig
    rm -fr /usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie.war
    cp /tmp/oozie.war /usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie.war
    rm -rf /usr/hdp/2.2.0.0-2041/oozie/oozie-server/webapps/oozie
  EOH
  action :nothing
  notifies :start,"service[start-oozie]", :immediately
end

service "start-oozie" do
  action :nothing
  service_name "oozie"
  supports :status => true, :restart => true, :reload => false
end

directory '/tmp/oozie-hbase-prep' do
  action :delete
  recursive true
end

file '/tmp/oozie.war' do
  action :delete
end
