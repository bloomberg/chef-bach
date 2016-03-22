#
# Cookbook Name:: bcpc
# Recipe:: mysql_connector
#
# Copyright (C) 2015 Bloomberg Finance L.P.
#

mysql_connector_name = "mysql-connector-java-#{node['bcpc']['mysql']['connector']['version']}"
mysql_package_dir = "#{Chef::Config[:file_cache_path]}/mysql_connector_package_dir"
target_filepath = "#{node['bcpc']['bin_dir']['path']}/#{node['bcpc']['mysql']['connector']['package']['name']}"

%w(ruby1.9.1-dev automake autoconf gcc make).each do |pkg|
  package pkg
end

gem_package 'fpm' do
  gem_binary '/usr/bin/gem'
  action :install
end

remote_file "#{Chef::Config[:file_cache_path]}/#{mysql_connector_name}.tar.gz" do
  source node['bcpc']['mysql']['connector']['url']
  mode '755'
  not_if { File.exists?(target_filepath) }
end

directory mysql_package_dir do
  action :create
  not_if { File.exists?(target_filepath) }
end

directory "#{mysql_package_dir}/usr/share/java/" do
  recursive true
  action :create
  not_if { File.exists?(target_filepath) }
end

bash 'extract-mysql-connector' do
  code "tar xvzf #{Chef::Config[:file_cache_path]}/#{mysql_connector_name}.tar.gz -C #{mysql_package_dir}/usr/share/java --no-anchored #{mysql_connector_name}-bin.jar --strip-components=1"
  not_if { File.exists?(target_filepath) }
end

directory "#{mysql_package_dir}/usr/share/maven-repo/mysql/mysql-connector-java/#{node['bcpc']['mysql']['connector']['version']}" do
  recursive true
  action :create
  not_if { File.exists?(target_filepath) }
end

file "#{mysql_package_dir}/usr/share/maven-repo/mysql/mysql-connector-java/#{node['bcpc']['mysql']['connector']['version']}/#{mysql_connector_name}.pom" do
  content <<-EOF
<?xml version='1.0' encoding='UTF-8'?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>#{node['bcpc']['mysql']['connector']['package']['name']}</version>
        <packaging>jar</packaging><properties>

                        <debian.originalVersion>#{node['bcpc']['mysql']['connector']['package']['name']}</debian.originalVersion>

                        <debian.package>libmysql-java</debian.package>
        </properties>   

        <name>MySQL Connector/J</name>
        <description>MySQL JDBC Type 4 driver</description>
        
        <licenses>
          <license>
            <name>The GNU General Public License, Version 2</name>
            <url>http://www.gnu.org/licenses/old-licenses/gpl-2.0.html</url>
            <distribution>repo</distribution>
            <comments>MySQL Connector/J contains exceptions to GPL requirements when linking with other components
        at are licensed under OSI-approved open source licenses, see EXCEPTIONS-CONNECTOR-J
         this distribution for more details.</comments>
          </license>
        </licenses>
        
        <url>http://dev.mysql.com/doc/connector-j/en/</url>
        
        <scm>
          <connection>scm:git:git@github.com:mysql/mysql-connector-j.git</connection>
          <url>https://github.com/mysql/mysql-connector-j</url>
        </scm>
        
        <organization>
          <name>Oracle Corporation</name>
          <url>http://www.oracle.com</url>
        </organization>
</project>
  EOF
  not_if { File.exists?(target_filepath) }
end

link "#{mysql_package_dir}/usr/share/maven-repo/mysql/mysql-connector-java/#{node['bcpc']['mysql']['connector']['version']}/#{mysql_connector_name}.jar" do
  to "../../../../java/#{mysql_connector_name}-bin.jar"
  not_if { File.exists?(target_filepath) }
end

link "#{mysql_package_dir}/usr/share/java/#{mysql_connector_name}.jar" do
  to "#{mysql_connector_name}-bin.jar"
  not_if { File.exists?(target_filepath) }
end

link "#{mysql_package_dir}/usr/share/java/mysql-connector-java.jar" do
  to "#{mysql_connector_name}-bin.jar"
  not_if { File.exists?(target_filepath) }
end

link "#{mysql_package_dir}/usr/share/java/mysql.jar" do
  to "#{mysql_connector_name}-bin.jar"
  not_if { File.exists?(target_filepath) }
end

bash 'build_mysql_connector_package' do
  cwd mysql_package_dir
  code %Q{
    fpm -s dir -t deb --prefix / \
        -n #{node['bcpc']['mysql']['connector']['package']['short_name']} \
        -v #{node['bcpc']['mysql']['connector']['version']} \
        -p #{target_filepath} \
        -C #{mysql_package_dir} \
        *
  }
  umask 0002
  notifies :run, 'bash[build_bins]', :delayed
  not_if { File.exist?(target_filepath) }
end
