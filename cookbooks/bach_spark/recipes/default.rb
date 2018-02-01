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

spark_pkg_version = node[:spark][:package][:version]
spark_bin_dir = node[:spark][:bin][:dir]

if node[:spark][:package][:install_meta] == true
  package 'spark' do
    action :upgrade
  end
else
  package "spark-#{spark_pkg_version}" do
    action :install
  end
end

template "#{spark_bin_dir}/conf/spark-env.sh" do
  source 'spark-env.sh.erb'
  mode 0o0755
  helper :config do
    node.bach_spark.environment.sort_by(&:first)
  end
  helpers(Spark::Configuration)
end

template "#{spark_bin_dir}/conf/spark-defaults.conf" do
  source 'spark-defaults.conf.erb'
  mode 0o0755
  helper :config do
    node[:bach_spark][:config].sort_by(&:first)
  end
  helpers(Spark::Configuration)
end

link "/#{spark_bin_dir}/yarn/spark-yarn-shuffle.jar" do
  to "#{spark_bin_dir}/yarn/spark-#{spark_pkg_version}-yarn-shuffle.jar"
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
