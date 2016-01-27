require 'spec_helper'

describe_recipe 'bcpc-hadoop::hdfs_user_directories' do
  %w{ldap-utils libsasl2-modules-gssapi-mit}.each do |pkg|
    it { expect(chef_run).to upgrade_package(pkg) }
  end
  it { expect(chef_run).to run_ruby_block('generate_user_dirs') }
end
