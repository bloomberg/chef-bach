#
# Cookbook Name:: webhdfs
# Resource:: hdfs_template
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
actions :create, :delete, :create_if_missing, :touch
default_action :create

# the URL or IP address list with their ports for the webhdfs endpoint
attribute :hosts, :kind_of => String, :required => true

# the path to create the directory
attribute :path, :kind_of => String, :name_attribute => true, :required => true

# the user account to carry on the actions on hdfs
attribute :user, :kind_of => String, :required => false

# access rights of users and groups to be set during create and chmod
attribute :mode, :kind_of => String, :required => false

# user id to which the owner ship of the directory to be changed to
attribute :owner, :kind_of => String, :required => false

# group to which the directory belongs adter chown or chgrp
attribute :group, :kind_of => String, :required => false

# the name of a template file, must end with .erb and locate under templates folder
attribute :source, :kind_of => String, :required => false

# A hash of variables that are passed into a hdfs_template file
attribute :variables, :kind_of => Hash, :required => false

# use kerberos in webhdfs ("on"/"off")
attribute :kerberos, :kind_of => String, :required => false
