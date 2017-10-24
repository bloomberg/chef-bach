package 'git'

user = node['bcpc']['bootstrap']['admin']['user']

directory 'repo directory' do
  path node['bach']['repository']['repo_directory']
  recursive true
  action :create
end

git 'chef-bach' do
  destination node['bach']['repository']['repo_directory']
  repository node['bach']['repository_test']['chef-bach']['uri'] 
  branch node['bach']['repository_test']['chef-bach']['branch'] 
  depth 1
  action :checkout
end

execute 'chown repo dir' do
  command "chown -R #{user} #{node['bach']['repository']['repo_directory']}"
end
