require 'chef'
require 'cheffish/rspec/chef_run_support'
require_relative '../../libraries/hive_metastore'

describe 'hive_metastore_database' do
  extend Cheffish::RSpec::ChefRunSupport

  let :resource do
    recipe do
      hive_metastore_database "run #{the_action}" do
        root_password 'therootpassword'
        hive_password 'thehivepassword'
        action the_action
      end
    end.resources.first
  end

  let :provider do
    resource.provider_for_action the_action
  end

  describe '#create' do
    let(:the_action) { :create }

    it 'checks if the database is created' do
      allow(provider).to receive(:create_hive_database)

      expect(provider).to receive(:database_created?)
      provider.run_action :create
    end

    it 'creates the database' do
      allow(provider).to receive(:database_created?).and_return(false)

      expect(provider).to receive(:create_hive_database)
      provider.run_action :create
    end

    it 'marks the resource as updated' do
      allow(provider).to receive(:database_created?).and_return(false)
      allow(provider).to receive(:create_hive_database)

      provider.run_action :create

      expect(resource).to be_updated
    end

    describe '#database_created?' do
      it 'shells out to mysql to with the root password' do
        expect(Mixlib::ShellOut).to receive(:new)
          .with(/mysql -uroot -ptherootpassword -e /)
          .and_return(Mixlib::ShellOut.new)
        provider.database_created?
      end
    end

    describe '#create_hive_database' do
      it 'passes the mysqlcommand to create the database' do
        privs = 'SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE'
        stdin = <<-eos
CREATE DATABASE metastore;
GRANT #{privs} ON metastore.* TO 'hive'@'%' IDENTIFIED BY 'thehivepassword';
GRANT #{privs} ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY 'thehivepassword';
FLUSH PRIVILEGES;
        eos

        expect(Mixlib::ShellOut).to receive(:new)
          .with(/mysql -uroot -ptherootpassword/, hash_including(input: stdin))
          .and_return(Mixlib::ShellOut.new)

        provider.create_hive_database
      end
    end

    context 'when the database is already created' do
      it 'doesn\'t create the database' do
        allow(provider).to receive(:database_created?).and_return(true)

        expect(provider).to_not receive(:create_hive_database)
        provider.run_action :create
      end

      it 'doesn\'t update the resource' do
        allow(provider).to receive(:database_created?).and_return(true)

        provider.run_action :create
        expect(resource).to_not be_updated
      end
    end
  end
end
