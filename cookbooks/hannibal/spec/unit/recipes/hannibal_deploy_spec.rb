# Test hannibal_hbase recipe.

require 'spec_helper'

# Test the local_tarball version (built from source locally)
describe 'hannibal::hannibal_deploy' do
   let(:chef_run) do
      ChefSpec::ServerRunner.new({ platform: 'ubuntu', version: '14.04'}) do |node|
         node.override['hannibal']['local_tarball'] = true
         node.override['hannibal']['hbase_version'] = 0.96
         node.override['hannibal']['zookeeper_quorum'] = 'http://localhost:2181'
         node.override[:hannibal][:log_dir] = '/var/log/hannibal'
         node.override[:hannibal][:install_dir] = '/usr/lib'
         node.override[:hannibal][:data_dir] = '/var/lib/hannibal/data'
         node.override[:hannibal][:user] = 'nobody'
         node.override[:hannibal][:owner] = 'root'
         node.override[:hannibal][:group] = 'root'
         node.override[:hannibal][:db] = 'mysql'
      end.converge(described_recipe)
   end

   it 'installs hannibal tarball' do
     expect(chef_run).to put_ark('hannibal')

     resource = chef_run.ark('hannibal')
     expect(resource).to notify('ruby_block[set_hannibal_file_permissions]').to(:run).immediately
   end

   it 'creates hannibal directories' do
      ['/var/log/hannibal', '/var/lib/hannibal/data'].each do |d|
         expect(chef_run).to create_directory(d).with(
            recursive: true,
            owner: 'nobody',
         )
      end
   end

   it 'creates service log file' do
      expect(chef_run).to create_file_if_missing('/var/log/hannibal/service.log').with(owner: 'nobody')
   end

   it 'creates hbase_site template with attributes' do
      expect(chef_run).to create_template('/usr/lib/hannibal/conf/hbase-site.xml').with(
         source: 'hannibal_hbase-site.xml.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644',
         variables: {:zk_hosts => 'http://localhost:2181'}
      )
   end

   it 'creates logger template with attributes' do
      expect(chef_run).to create_template('/usr/lib/hannibal/conf/logger.xml').with(
         source: 'hannibal_logger.xml.erb',
         owner:  'root',
         group:  'root',
         mode: '0644'
      )
   end

   it 'creates application conf template with attributes' do
      expect(chef_run).to create_template('/usr/lib/hannibal/conf/application.conf').with(
         source: 'hannibal_application.conf.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644'
      )
   end

   it 'creates start script template with attributes' do
      expect(chef_run).to create_template('/usr/lib/hannibal/start').with(
         source: 'hannibal_start.erb',
         owner:  'root',
         group:  'root'
      )
   end

   it 'creates upstart conf template with attributes' do
      expect(chef_run).to create_template('/etc/init/hannibal.conf').with(
         source: 'hannibal.upstart.conf.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644'
      )
   end

   it 'sets directory permissions' do
      ['/usr/lib/hannibal', '/usr/lib/hannibal/share', '/usr/lib/hannibal/lib', '/usr/lib/hannibal/bin', '/usr/lib/hannibal/conf', '/usr/lib/hannibal/start'].each do |d|
         expect(chef_run).to create_directory(d).with(mode: '0755')
      end
   end

   it 'sets hannibal file permissions' do
      resource = chef_run.ruby_block('set_hannibal_file_permissions')
      expect(resource).to do_nothing 
   end

   it 'starts hannibal service with attributes' do
      expect(chef_run).to enable_service('hannibal')
      expect(chef_run).to start_service('hannibal').with(
         provider: Chef::Provider::Service::Upstart
      )

      resource = chef_run.service('hannibal')
      expect(resource).to subscribe_to('template[application_conf]').on(:restart).delayed
      expect(resource).to notify('ruby_block[wait_for_hannibal]').to(:run).delayed
   end
   
   it 'waits for service to start' do
      resource = chef_run.ruby_block('wait_for_hannibal') 
      expect(resource).to do_nothing
   end

end
