apt_repository "canonical-support-tools" do
  uri node['bcpc']['repos']['ubuntu-tools']
  distribution node['bcpc']['ubuntu']['version']
  components ["main"]
  key "ubuntu-support-tools.key" 
end

package "python-software-properties" do
  action :upgrade
end

package "sosreport" do
  action :upgrade
end

