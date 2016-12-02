%w(hive webhcat hcat hive-hcatalog).each do |w|
  directory "/etc/#{w}/conf.#{node.chef_environment}" do
    owner 'root'
    group 'root'
    mode 00755
    action :create
    recursive true
  end

  bach_hive_poise_alternatives "update-#{w}-conf-alternatives" do
    action :create
    component w
    link_name node.chef_environment
  end
end
