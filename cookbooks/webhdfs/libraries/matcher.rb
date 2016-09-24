#
# Cookbook Name:: webhdfs
# Matcher for chefspec
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
if defined?(ChefSpec)
  def create_webhdfs_hdfs_directory(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_directory, :create, resource_name)
  end

  def delete_webhdfs_hdfs_directory(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_directory, :delete, resource_name)
  end
  
  def create_webhdfs_hdfs_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_file, :create, resource_name)
  end
  
  def create_if_missing_webhdfs_hdfs_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_file, :create_if_missing, resource_name)
  end

  def touch_webhdfs_hdfs_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_file, :touch, resource_name)
  end

  def delete_webhdfs_hdfs_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_file, :delete, resource_name)
  end

  def create_webhdfs_hdfs_template(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_template, :create, resource_name)
  end
  
  def create_if_missing_webhdfs_hdfs_template(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_template, :create_if_missing, resource_name)
  end

  def touch_webhdfs_hdfs_template(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_template, :touch, resource_name)
  end

  def delete_webhdfs_hdfs_template(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:webhdfs_hdfs_template, :delete, resource_name)
  end
end

