include_recipe "bach_krb5::default"
include_recipe "krb5::kadmin"
include_recipe "krb5::kadmin_service"

template "/etc/krb5kdc/kdc.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  source "kdc.conf.erb"
  cookbook "krb5"
  variables node['krb5']['kdc_conf']
end

include_recipe "krb5::kadmin_init"

kdc_resource = resources("service[krb5-kdc]")
kdc_resource.supports(:status => true, :restart => true, :reload => false)
kdc_resource.action([:enable, :start])
kdc_resource.subscribes(:restart, "template #{node['krb5']['data_dir']}/kdc.conf", :delayed) 

kadm_resource = resources("service[krb5-admin-server]")
kadm_resource.supports(:status => true, :restart => true, :reload => false)
kadm_resource.action([:enable, :start])
kadm_resource.subscribes(:restart, "template node['krb5']['kdc_conf']['realms'][default_realm]['acl_file']", :delayed)

include_recipe "bach_krb5::gems"
