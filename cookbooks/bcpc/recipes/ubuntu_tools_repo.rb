bcpc_repo 'canonical-support-tools' do
  arch 'amd64'
end

package "python-software-properties" do
  action :upgrade
end

package "sosreport" do
  action :upgrade
end

package "traceroute" do
  action :upgrade
end

package "iotop" do
  action :upgrade
end
