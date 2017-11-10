require 'poise'

module BcpcHadoop
  module HiveMetastore
    module Database
    end
  end
end

module BcpcHadoop::HiveMetastore::Database
  class UpgradeError < RuntimeError; end

  class Resource < Chef::Resource
    include Poise

    provides :hive_metastore_database

    attribute :dbadmin_username, kind_of: String, default: 'root'
    attribute :dbadmin_password, kind_of: String
    attribute :metastore_db_username, kind_of: String, default: 'hive'
    attribute :metastore_db, kind_of: String, default: 'metastore'
    attribute :metastore_db_host, kind_of: String, default: 'localhost' 
    attribute :metastore_db_port, kind_of: Fixnum, default: 3306
    attribute :metastore_db_password, kind_of: String
    attribute :schematool_path, kind_of: String

    actions :create, :init, :upgrade
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
      command = Mixlib::ShellOut.new "mysql -u#{new_resource.dbadmin_username} -p#{new_resource.dbadmin_password} -h#{new_resource.metastore_db_host} -P#{new_resource.metastore_db_port}",
        input: <<~eos
          CREATE DATABASE #{new_resource.metastore_db};
          GRANT #{privs} ON #{new_resource.metastore_db}.* TO '#{new_resource.metastore_db_username}'@'%' IDENTIFIED BY '#{new_resource.metastore_db_password}';
          GRANT #{privs} ON #{new_resource.metastore_db}.* TO '#{new_resource.metastore_db_username}'@'localhost' IDENTIFIED BY '#{new_resource.metastore_db_password}';
          FLUSH PRIVILEGES;
        eos
      command.run_command
    end

    def database_created?
      command = Mixlib::ShellOut.new "mysql -u#{new_resource.dbadmin_username} -p#{new_resource.dbadmin_password} -h#{new_resource.metastore_db_host} -P#{new_resource.metastore_db_port} -e "\
          '\'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA '\
          "WHERE SCHEMA_NAME = \"#{new_resource.metastore_db}\"' | grep -q metastore"
      command.run_command
      command.exitstatus == 0
    end

    def action_init
      return if schema_initialized?
      converge_by 'initializing the schema to 1.2.0' do
        do_initialize_schema
      end
    end

    def do_initialize_schema
      cmd = Mixlib::ShellOut.new "#{new_resource.schematool_path} -dbType mysql "\
        "-userName #{new_resource.dbadmin_username} -passWord #{new_resource.dbadmin_password} "\
          '-initSchemaTo 1.2.0'
      cmd.run_command
    end

    def schema_initialized?
      schema_info = Mixlib::ShellOut.new "#{new_resource.schematool_path} -dbType mysql -info"
      schema_info.run_command
      !(schema_info.stderr =~ /metastore.VERSION' doesn't exist/) &&
        (schema_info.stdout =~ /Metastore schema version:\s+\d+\.\d+\.\d+/)
    end

    # schematool -upgradeSchema is idempotent. So we just inspect the output if
    # it indeed do a noop.
    def action_upgrade
      cmd = Mixlib::ShellOut.new "#{new_resource.schematool_path} -dbType mysql "\
        "-userName #{new_resource.dbadmin_username} -passWord #{new_resource.dbadmin_password} "\
          '-upgradeSchema'
      cmd.run_command

      if cmd.stdout =~ /Starting upgrade metastore schema from version.*\nUpgrade script/
        new_resource.updated_by_last_action true
      elsif cmd.stdout =~ /No schema upgrade required from version.*/
        new_resource.updated_by_last_action false
      else
        error_details = cmd.format_for_exception.gsub(/passWord \w+/, 'passWord <scrubbed>')
        raise UpgradeError, 'Unexpected error when running upgrade' + "\n" + error_details
      end
    end
  end
end
