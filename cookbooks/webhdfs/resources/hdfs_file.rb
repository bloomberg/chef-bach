#
# Cookbook Name:: webhdfs
# Resource:: hdfs_file
#
# Copyright 2015, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
actions :create, :delete, :touch, :create_if_missing, :append, :rename
default_action :create

# name for the resource
attribute :name, :kind_of => String, :name_attribute => true, :required => true

# the list of URL or IP address and ports for the webhdfs endpoint
attribute :hosts, :kind_of => String, :required => true

# the visiting point for the endpoint
attribute :port, :kind_of => String, :required => true

# the path to create the file
attribute :path, :kind_of => String, :name_attribute => true, :required => true

# the new name the hdfs file as renamed for the resource
attribute :new_name, :kind_of => String, :required => false

# the user account to carry on the actions on hdfs
attribute :user, :kind_of => String, :required => false

# access rights of users and groups to be set during create and chmod
attribute :mode, :kind_of => String, :required => false

# user id to which the owner ship of the file to be changed to
attribute :owner, :kind_of => String, :required => false

# group to which the file belongs adter chown or chgrp
attribute :group, :kind_of => String, :required => false

# the content to write in the hdfs file
attribute :content, :kind_of => String, :required => false 

# the overwrite option to a hdfs file
attribute :overwrite, :kind_of => [TrueClass, FalseClass], :required => false

# the replication number of the file
attribute :replication, :kind_of => Integer, :required => false

# use kerberos in webhdfs ("on"/"off")
attribute :kerberos, :kind_of => String, :required => false
