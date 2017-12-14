# Cookbook name : hdfsdu
# Recipe name   : create_user.rb
# Description   : Create hdfsdu hdfs user and directorie

service_user = node['hdfsdu']['service_user']
hdfsdu_user = node['hdfsdu']['hdfsdu_user']

user service_user do
  comment 'hdfsdu service user'
end

user hdfsdu_user do
  comment 'hdfsdu user'
end
