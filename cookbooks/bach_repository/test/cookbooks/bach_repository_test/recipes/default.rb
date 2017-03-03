package 'git'

git 'chef-bach' do
  destination node['bach']['repository']['repo_directory']
  repository node['bach']['repository_test']['chef-bach']['uri'] 
  branch node['bach']['repository_test']['chef-bach']['branch'] 
  depth 1
  action :checkout
end

execute 'chown repo dir' do
  command "chown -R vagrant #{node['bach']['repository']['repo_directory']}"
end
