case node["platform_family"]
  when "debian"
    apt_repository "hortonworks" do
      uri node['bcpc']['repos']['hortonworks']
      distribution node[:bcpc][:hadoop][:distribution][:version]
      components ["main"]
      arch "amd64"
      key node[:bcpc][:hadoop][:distribution][:key]
    end
    apt_repository "hdp-utils" do
      uri node['bcpc']['repos']['hdp_utils']
      distribution "HDP-UTILS"
      components ["main"]
      arch "amd64"
      key node[:bcpc][:hadoop][:distribution][:key]
    end
  when "rhel"
    ""
    # do things on RHEL platforms (redhat, centos, scientific, etc)
end

