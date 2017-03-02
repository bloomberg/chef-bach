package 'git'

git 'chef-bach' do
  destination node['bach']['repository']['repo_directory']
  repository 'https://github.com/bloomberg/chef-bach'
  depth 1
  action :checkout
end

execute 'chown repo dir' do
  command "chown -R vagrant #{node['bach']['repository']['repo_directory']}"
end
