#
# Copyright 2015, Bloomberg Finance L.P.
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

default[:bach][:sqoop][:install_dir] = '/usr/lib/sqoop'

default[:bach][:sqoop][:lib_dir] =
  default[:bach][:sqoop][:install_dir] + '/lib'

# Place JDBC jars in this hash.
# They will be installed to the sqoop lib_dir.
default[:bach][:sqoop][:jdbc_jars] =
  {
   'mysql-connector-java.jar' =>
     {
      'url' =>
        'http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.36/mysql-connector-java-5.1.36.jar',
      'checksum' =>
        '7ba5290be5844b5bbdae3e4bee7e6a86b62b5feeacd224b60e66530df40a307a'
     }                                   
  }

default[:bach][:sqoop][:zookeeper_conf_dir] = '/etc/zookeeper/conf'
