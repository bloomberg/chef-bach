#
# Cookbook Name:: bach_spark
# Recipe:: default
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This recipe installs spark to /usr/spark/ using a package
# pre-generated on the bootstrap VM.  See bach_repository::spark for
# the fpm invocation that creates the debian package.
#

spark_bin_dir = node['spark']['bin']['dir']
spark_conf_dir = node['spark']['conf']['dir']
spark_active_release = node[:bcpc][:hadoop][:distribution][:active_release]

directory "/etc/spark2/conf.#{node.chef_environment}" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

bash 'update-spark2-conf-alternatives' do
  code 'update-alternatives --install /etc/spark2/conf spark2-conf ' \
  "/etc/spark2/conf.#{node.chef_environment} 50\n" \
  'update-alternatives --set spark2-conf ' \
  "/etc/spark2/conf.#{node.chef_environment}\n"
end

package 'spark2' do
  action :upgrade
end

hdp_select('spark2-client', spark_active_release)

template "#{spark_conf_dir}/spark-env.sh" do
  source 'spark-env.sh.erb'
  mode 0o0755
  helper :config do
    node.bach_spark.environment.sort_by(&:first)
  end
  helpers(Spark::Configuration)
end

template "#{spark_conf_dir}/spark-defaults.conf" do
  source 'spark-defaults.conf.erb'
  mode '00755'
  helper :config do
    node[:bach_spark][:config].sort_by(&:first)
  end
  helpers(Spark::Configuration)
end

# For backward compatibility

directory '/usr/spark' do
  action :create
  mode '00755'
end

link '/usr/spark/current' do
  to spark_bin_dir
end

# Spark 2.x expects to dynamically link LZO.
package 'liblzo2-2' do
  action :upgrade
end

# install fortran libs needed by some jobs
package 'libatlas3gf-base' do
  action :upgrade
end

package 'libopenblas-base' do
  action :upgrade
end
