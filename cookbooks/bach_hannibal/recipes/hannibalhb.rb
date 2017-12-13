include_recipe 'bcpc-hadoop::mysql_connector'

link "#{node[:hannibal][:install_dir]}/hannibal/lib/mysql-connector-java.jar" do
 to "/usr/share/java/mysql-connector-java.jar"
end

make_config('hannibal-app-secret-key', secure_password(64))

node.force_default['hannibal']['app_secret_key'] = get_config('hannibal-app-secret-key')

node.force_default['hannibal']['hbase_site']['hbase.zookeeper.quorum'] = 
  node[:bcpc][:hadoop][:zookeeper][:servers].map{ |s| float_host(s[:hostname])}.join(",")

node.force_default['hannibal']['hbase_site']['hbase.zookeeper.property.clientPort'] = 
  node[:bcpc][:hadoop][:zookeeper][:port]

node.force_default['hannibal']['hbase_site']['hbase.rootdir'] =  "hdfs://#{node.chef_environment}/hbase"

node.force_default[:hannibal][:service_endpoint] = 
  "http://#{float_host(node[:fqdn])}:#{node[:hannibal][:port]}/api/heartbeat"

if node[:bcpc][:hadoop][:kerberos][:enable] == true 
then

  configure_kerberos 'hannibal_kerb' do
    service_name 'hannibal'
  end

  node.force_default['hannibal']['hbase_site']['hbase.security.authentication'] = 'kerberos'

  node.force_default['hannibal']['hbase_site']['hadoop.security.authentication'] = 'kerberos'

  node.force_default['hannibal']['hbase_site']['hbase.master.kerberos.principal'] = 
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/" +
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"

  node.force_default['hannibal']['hbase_site']['hbase.regionserver.kerberos.principal'] =
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"

  node.force_default['hannibal']['hbase_site']['hannibal.kerberos.keytab'] =
    "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hannibal][:keytab]}"

  node.force_default['hannibal']['hbase_site']['hannibal.kerberos.principal'] =
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hannibal][:principal]}/#{float_host(node[:fqdn])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"

end
