%w{pig }.each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "hadoop-detect-javahome" do
  path "/usr/lib/bigtop-utils/bigtop-detect-javahome"
  source "hdp_bigtop-detect-javahome.erb"
  owner "root"
  group "root"
  mode "0755"
end


