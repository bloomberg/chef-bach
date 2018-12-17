include_recipe 'bcpc::admin_base'

ruby_block 'oozie databags' do
  block do
    make_config('oozie-keystore-password', secure_password)
  end
  only_if { get_config('oozie-keystore-password').nil? }
end
