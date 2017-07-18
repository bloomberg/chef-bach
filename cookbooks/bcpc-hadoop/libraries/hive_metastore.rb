require 'poise'

module BcpcHadoop
  module HiveMetastore
    module Database
    end
  end
end

module BcpcHadoop::HiveMetastore::Database
  class Resource < Chef::Resource
    include Poise

    provides :hive_metastore_database

    attribute :root_password, kind_of: String
    attribute :hive_password, kind_of: String

    actions :create
  end

  class Provider < Chef::Provider
    include Poise

    provides :hive_metastore_database

    def action_create
      return if database_created?
      converge_by 'creating the metastore database' do
        create_hive_database
      end
    end

    def create_hive_database
      privs = 'SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE'
      command = Mixlib::ShellOut.new "mysql -uroot -p#{new_resource.root_password}",
        input: <<-eos
CREATE DATABASE metastore;
GRANT #{privs} ON metastore.* TO 'hive'@'%' IDENTIFIED BY '#{new_resource.hive_password}';
GRANT #{privs} ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY '#{new_resource.hive_password}';
FLUSH PRIVILEGES;
        eos
      command.run_command
    end

    def database_created?
      command = Mixlib::ShellOut.new "mysql -uroot -p#{new_resource.root_password} -e "\
          '\'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA '\
          'WHERE SCHEMA_NAME = "metastore"\' | grep -q metastore'
      command.run_command
      command.exitstatus == 0
    end
  end
end
