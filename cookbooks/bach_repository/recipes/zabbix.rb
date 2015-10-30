#
# Cookbook Name:: bach_repository
# Recipe:: zabbix
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']

# If the zabbix version is changed, the zabbixapi gem version will
# also need to be altered (in the 'gems' recipe.)
zabbix_version = '2.2.9'

# Zabbix uses this, so it went in the Zabbix recipe.
#
# fpm's auto-download uses easy_install
# easy_install ignores SSL_CERT_FILE
# result: we must manually untar before using fpm
#
requests_aws_path = "#{src_dir}/requests-aws-0.1.5"

remote_file "#{requests_aws_path}.tar.gz" do
  source 'https://pypi.python.org/packages/source/r/requests-aws/requests-aws-0.1.5.tar.gz'
  checksum 'f909127d270f204ce171881e11369bc410b402dcfdb5611cef58abc302e020da'
end

execute "tar -xzf #{requests_aws_path}.tar.gz" do
  cwd src_dir
  creates requests_aws_path
end

execute "fpm -s python -t deb -v 0.1.5 #{requests_aws_path}/setup.py" do
  cwd bins_dir
  creates "#{bins_dir}/python-requests-aws_0.1.5_all.deb"
end

# This is an official Zabbix-created Github mirror of svn.zabbix.com.
git "#{src_dir}/zabbix-#{zabbix_version}" do
  repository 'https://github.com/zabbix/zabbix.git'
  revision zabbix_version
  not_if{ 
    File.exists?("#{bins_dir}/zabbix-agent.tar.gz") &&
    File.exists?("#{bins_dir}/zabbix-server.tar.gz") 
  }
  retries 5
end

package 'pkg-config'

execute "create_zabbix_configure_script" do
  cwd "#{src_dir}/zabbix-#{zabbix_version}"
  command "./bootstrap.sh"
  creates "#{src_dir}/zabbix-#{zabbix_version}/configure"
end

execute "build_zabbix_source_distribution" do
  cwd "#{src_dir}/zabbix-#{zabbix_version}"
  command "./configure && make dbschema"
  creates "#{src_dir}/zabbix-#{zabbix_version}" +
    "/src/libs/zbxdbhigh/dbschema.c"
end

execute "create_zabbix_tarball" do
  cwd src_dir
  command "tar -czf zabbix-#{zabbix_version}.tar.gz zabbix-#{zabbix_version}"
  creates "#{src_dir}/zabbix-#{zabbix_version}.tar.gz"
end

bash 'build_zabbix_agent' do
  cwd src_dir
  code( 
  <<-EOF
    rm -rf /tmp/zabbix-install && mkdir -p /tmp/zabbix-install
    tar -xzf zabbix-#{zabbix_version}.tar.gz && \
    cd zabbix-#{zabbix_version} && \
    ./configure --prefix=/tmp/zabbix-install --enable-agent --with-ldap && \
    make install && \
    tar zcf #{bins_dir}/zabbix-agent.tar.gz -C /tmp/zabbix-install ./
  EOF
  )
  creates "#{bins_dir}/zabbix-agent.tar.gz"
end

bash 'build_zabbix_server' do
  cwd src_dir
  code( 
  <<-EOF
    rm -rf /tmp/zabbix-install && mkdir -p /tmp/zabbix-install
    tar -xzf zabbix-#{zabbix_version}.tar.gz && \
    cd zabbix-#{zabbix_version} && \
    ./configure --prefix=/tmp/zabbix-install --enable-server --with-mysql --with-ldap && \
    make install && \
    cp -a frontends/php /tmp/zabbix-install/share/zabbix/ && \
    cp database/mysql/* /tmp/zabbix-install/share/zabbix/ && \
    tar -czf #{bins_dir}/zabbix-server.tar.gz -C /tmp/zabbix-install ./
  EOF
  )
  creates "#{bins_dir}/zabbix-server.tar.gz"
end

directory '/tmp/zabbix-install' do
  recursive true
  action :delete
end

[
 "#{bins_dir}/python-requests-aws_0.1.5_all.deb",
 "#{bins_dir}/zabbix-agent.tar.gz",
 "#{bins_dir}/zabbix-server.tar.gz",
].each do |path|
  file path do
    mode 0444
  end
end
