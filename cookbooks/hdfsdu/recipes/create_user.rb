# Cookbook name : hdfsdu
# Recipe name   : create_user.rb
# Description   : Create hdfsdu hdfs user and directorie
                  
hdfsdu_user = node[:hdfsdu][:hdfs_user]
hdfsdu_user_group = node[:hdfsdu][:hdfs_user_group] 

group hdfsdu_user_group do
   action :create
end

user hdfsdu_user do
   comment "hdfsdu user"
   gid hdfsdu_user_group 
end
