
# Create directory to store keytab files
directory node[:bcpc][:hadoop][:kerberos][:keytab][:dir] do
  owner "root"
  group "root"
  recursive true
  mode 0755
  only_if { node[:bcpc][:hadoop][:kerberos][:enable] }
end
