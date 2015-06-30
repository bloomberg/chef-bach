

ark "ambari_server" do
  url node[:ambari][:tar][:url]
  version '2.0.1'
  path "/tmp"
  action :put
  notifies :run,"bash[extracting_package]", :immediately
  not_if { ::File.exists?(node[:ambari][:install_dir])}
end


bash "extracting_package" do
cwd node[:ambari][:install_dir]
code <<EOH
dpkg-deb -x "#{node[:ambari][:deb_path]}" "#{node[:ambari][:temp_dir]}"
dpkg-deb --control "#{node[:ambari][:deb_path]}" "#{node[:ambari][:temp_dir]}/DEBIAN"
EOH
notifies :run,"bash[Editing_Control_File]", :immediately
end

bash "Editing_Control_File" do
  code <<EOH
    sed -i 's/, postgresql (>= 8.1)//' "#{node[:ambari][:temp_dir]}/DEBIAN/control"
EOH
  only_if { ::File.exists?("#{node[:ambari][:temp_dir]}/DEBIAN/control")}
end



bash 'building package' do
  code <<EOH
    dpkg -b #{node[:ambari][:temp_dir]} #{node[:ambari][:new_deb_path]}
    cp #{node[:ambari][:new_deb_path]} #{node[:ambari][:bins_dir]}
    rm -rf  #{node[:ambari][:temp_dir]} #{node[:ambari][:new_deb_path]} #{node[:ambari][:install_dir]}
EOH
end

bash "Executing Build Bins Script" do
  cwd /home/vagrant/chef-bcpc
  code <<EOH
    ./build_bins.sh 
EOH
end

