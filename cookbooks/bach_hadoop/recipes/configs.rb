require 'base64'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

# disable IPv6 (e.g. for HADOOP-8568)
case node["platform_family"]
  when "debian"
    %w{net.ipv6.conf.all.disable_ipv6
       net.ipv6.conf.default.disable_ipv6
       net.ipv6.conf.lo.disable_ipv6}.each do |param|
      sysctl_param param do
        value 1
      end
    end
  else
   Chef::Log.warn "============ Unable to disable IPv6 for non-Debian systems"
end

# ensure we use /etc/security/limits.d to allow ulimit overriding
if not node.has_key?('pam_d') or not node['pam_d'].has_key?('services') or not node['pam_d']['services'].has_key?('common-session')
  node.default['pam_d']['services'] = {
    'common-session' => {
      'main' => {
        'pam_permit_default' => {
          'interface' => 'session', 'control_flag' => '[default=1]', 'name' => 'pam_permit.so' },
        'pam_deny' => {
          'interface' => 'session', 'control_flag' => 'requisite', 'name' => 'pam_deny.so' },
        'pam_permit_required' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_permit.so' },
        'pam_limits' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_limits.so' },
        'pam_umask' => {
          'interface' => 'session', 'control_flag' => 'optional', 'name' => 'pam_umask.so' },
        'pam_unix' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_unix.so' }
      },
      'includes' => []
    }
  }
   
end

# set vm.swapiness to 0 (to lessen swapping)
include_recipe 'sysctl::default'
sysctl_param 'vm.swappiness' do
  value 0
end

# Populate node attributes for all kind of hosts
set_hosts

package "bigtop-jsvc"

template "hadoop-detect-javahome" do
  path "/usr/lib/bigtop-utils/bigtop-detect-javahome"
  source "hdp_bigtop-detect-javahome.erb"
  owner "root"
  group "root"
  mode "0755"
end

package "hdp-select" do
  action :upgrade
end

# Install Java
include_recipe "java::default"
include_recipe "java::oracle_jce"

%w{zookeeper}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :upgrade
  end
end

# Create Keytabs (if kerberos is eanbled)
if node[:bcpc][:hadoop][:kerberos][:enable] == true then

  keytab_dir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]
  
  # Create directory to store keytab files
  directory "#{keytab_dir}" do
    owner "root"
    group "root"
    recursive true
    mode 0755  
  end

  # Download and create keytab file
  node[:bcpc][:hadoop][:kerberos][:data].each do |srvc, srvdat|
  
    keytab_file = srvdat['keytab']

    config_host = srvdat['princhost'] == "_HOST" ?  float_host(node[:hostname]) : srvdat['princhost'].split('.')[0]
    
    # Delete existing keytab if keytab is being re-created
    file "#{keytab_dir}/#{keytab_file}" do
      action :delete
      only_if { 
        File.exists?("#{keytab_dir}/#{keytab_file}") && 
        node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
      }
    end 

    # Create the keytab file
    file "#{keytab_dir}/#{keytab_file}" do
      owner "#{srvdat['owner']}"
      group "root"
      mode "#{srvdat['perms']}"
      action :create_if_missing
      content Base64.decode64(get_config!("#{config_host}-#{srvc}"))
      only_if { user_exists?("#{srvdat['owner']}")  }
    end

    princ_host = srvdat['princhost'] == "_HOST" ? float_host(node[:fqdn]) : srvdat['princhost']

    next if srvdat['principal'] == "HTTP"

    execute "kdestroy-for-#{srvdat['owner']}" do
      command "kdestroy"
      user "#{srvdat['owner']}"
      action :run
      only_if { user_exists?("#{srvdat['owner']}") }
    end

    execute "kinit-for-#{srvdat['owner']}" do
    command "kinit -kt #{keytab_dir}/#{keytab_file} #{srvdat['principal']}/#{princ_host}"
      action :run
      user "#{srvdat['owner']}"
      only_if { user_exists?("#{srvdat['owner']}") }
    end
  end
end
