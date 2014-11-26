# Test hannibal_hbase recipe.
# Run from directory ~/chef-bcpc/cookbooks/hannibal/spec
# Command: rspec tests/hannibal_hbase_spec.rb --color --format documentation

require_relative '../spec_helper'

# Test the local_tarball version (built from source locally)
describe 'hannibal::hannibal_hbase' do
   let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
         node.set['hannibal']['local_tarball'] = true
         node.set['hannibal']['hbase_version'] = 0.96
         node.set['bcpc']['hadoop']['zookeeper']['servers'] = 'http://localhost:2181'
         node.set[:hannibal][:log_dir] = '/var/log/hannibal'
         node.set[:hannibal][:install_dir] = '/usr/lib'
         node.set[:hannibal][:data_dir] = '/var/lib/hannibal/data'
         node.set[:hannibal][:user] = 'nobody'
         node.set[:hannibal][:owner] = 'root'
         node.set[:hannibal][:group] = 'root'
         node.set[:hannibal][:db] = "mysql"
      end.converge(described_recipe)
   end

   it "downloads hannibal tarball" do
     expect(chef_run).to create_remote_file("#{Chef::Config['file_cache_path']}/hannibal-hbase0.96.tgz")

     resource = chef_run.remote_file("#{Chef::Config['file_cache_path']}/hannibal-hbase0.96.tgz")
     expect(resource).to notify('bash[unzip_hannibal]').to(:run).immediately
   end

   it 'unzips hannibal to install directory' do
      expect(chef_run).to run_bash("unzip_hannibal").with(cwd: "#{Chef::Config['file_cache_path']}")
   end

   it "creates hannibal directories" do
      ["/var/log/hannibal", "/var/lib/hannibal/data"].each do |d|
         expect(chef_run).to create_directory(d).with(
            recursive: true,
            owner: 'nobody',
         )
      end
   end

   it "creates service log file" do
      expect(chef_run).to create_file_if_missing("/var/log/hannibal/service.log").with(owner: 'nobody')
   end

   it 'creates hbase_site template with attributes' do
      expect(chef_run).to create_template("/usr/lib/hannibal/conf/hbase-site.xml").with(
         source: 'hannibal_hbase-site.xml.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644',
         variables: {:zk_hosts => 'http://localhost:2181'}
      )
   end

   it 'creates logger template with attributes' do
      expect(chef_run).to create_template("/usr/lib/hannibal/conf/logger.xml").with(
         source: 'hannibal_logger.xml.erb',
         owner:  'root',
         group:  'root',
         mode: '0644'
      )
   end

   it 'creates application conf template with attributes' do
      expect(chef_run).to create_template("/usr/lib/hannibal/conf/application.conf").with(
         source: 'hannibal_application.conf.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644'
      )
   end

   it 'creates start script template with attributes' do
      expect(chef_run).to create_template("/usr/lib/hannibal/start").with(
         source: 'hannibal_start.erb',
         owner:  'root',
         group:  'root',
         mode:   '0645'
      )
   end

   it 'creates upstart conf template with attributes' do
      expect(chef_run).to create_template("/etc/init/hannibal.conf").with(
         source: 'hannibal.upstart.conf.erb',
         owner:  'root',
         group:  'root',
         mode:   '0644'
      )
   end

   it 'creates evolutions templates with attributes' do
      [1, 2, 3, 4, 5].each do |tmpl|
         expect(chef_run).to create_template("/usr/lib/hannibal/conf/evolutions/default/#{tmpl}.sql").with(
            source: "hannibal_#{tmpl}.sql.erb",
            owner: 'root',
            group: 'root'
          )
      end
   end

   it "creates hannibal database and configures privileges" do
      expect(chef_run).to run_ruby_block("hannibal-database-creation")
   end

   it 'sets directory permissions' do
      ["/usr/lib/hannibal", "/usr/lib/hannibal/share", "/usr/lib/hannibal/lib", "/usr/lib/hannibal/bin", "/usr/lib/hannibal/conf", "/usr/lib/hannibal/start"].each do |d|
         expect(chef_run).to create_directory(d).with(mode: '0755')
      end
   end

   it "sets hannibal file permissions" do
      expect(chef_run).to run_bash("set_hannibal_file_permissions").with(
         cwd: "/usr/lib/hannibal"
      )
   end

   it 'starts hannibal service with attributes' do
      expect(chef_run).to start_service("hannibal").with(
         provider: Chef::Provider::Service::Upstart       
      )
   end
   
   it 'waits for service to start' do
      expect(chef_run).to run_ruby_block("wait_for_hannibal") 
   end

end
