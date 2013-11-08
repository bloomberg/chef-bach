
%w{hadoop-hdfs-journalnode}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "hadoop-hdfs-journalnode" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end



