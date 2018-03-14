#
# This module holds utility methods shared between repxe_host.rb and
# cluster_assign_roles.rb.
#
# Most of the methods use the Chef Client or talk to the Chef Server
#
require 'json'

# pry is not required but nice to have
begin
  require 'pry'
rescue LoadError
end

#
#
# Workaround log spam in older versions of ChefDK.
#
# https://github.com/berkshelf/berkshelf/pull/1668/
# https://github.com/intridea/hashie/issues/394
#
begin
  require 'hashie'
  require 'hashie/logger'
  Hashie.logger = Logger.new(nil)
rescue LoadError
end

require 'chef'
require 'chef-vault'
require 'ohai'
require 'ridley'
Ridley::Logging.logger.level = Logger.const_get 'ERROR'

module BACH

  #
  # Methods to get data about a BACH cluster
  #
  module ClusterData

    #
    # Methods which only run on machines with Chef credentials
    # or on the Chef Server
    #
    module ChefNode

      def chef_environment
        ridley.environment.find(chef_environment_name)
      end

      #
      # Returns the password for the 'ubuntu' account in plaintext.
      # The method name comes from the confusing name of the data bag item.
      #
      def cobbler_root_password
        # Among other things, Ridley will set up Chef::Config for ChefVault.
        unless ridley.data_bag.find('os/cobbler_keys')
          raise('No os/cobbler_keys data bag item found. ' \
                'Is this cluster using chef-vault?')
        end

        ChefVault::Item.load('os', 'cobbler')['root-password']
      end

      def refresh_vault_keys(entry = nil)
        reindex_and_wait(entry) if entry

        #
        # Vault data bags can be identified by distinctively named data
        # bag items ending in "_keys".
        #
        # Here we build a list of all the vaults by looking for "_keys"
        # and ignoring any data bags that contain no vault-items.
        #
        vault_list = ridley.data_bag.all.map do |db|
          vault_items = db.item.all.map do |dbi|
            dbi.chef_id.gsub(/_keys$/, '') if dbi.chef_id.end_with?('_keys')
          end.compact

          { db.name => vault_items } if vault_items.any?
        end.compact.reduce({}, :merge)

        vault_list.each do |vault, item_list|
          item_list.each do |item|
            begin
              vv = ChefVault::Item.load(vault, item)
              vv.refresh
              vv.save
              puts "Refreshed chef-vault item #{vault}/#{item}"
            rescue
              $stderr.puts "Failed to refresh chef-vault item #{vault}/#{item}!"
            end
          end
        end
      end

      def reindex_chef_server
        cc = Mixlib::ShellOut.new('sudo', 'chef-server-ctl', 'reindex')
        result = cc.run_command
        cc.error!
        result
      end

      def reindex_and_wait(entry)
        180.times do |i|
          if ridley.search(:node, "name:#{entry[:fqdn]}").any?
            puts "Found #{entry[:fqdn]} in search index"
            return
          else
            if i % 60 == 0
              puts "Waiting for #{entry[:fqdn]} to appear in Chef index..."
            # the #times method counts up, not down, so i == 179 on the 180th
            # iteration.
            elsif i == 179
              raise "Did not find indexed node for #{entry[:fqdn]} " \
                "after #{timeout} secs! Reindex by hand or wait again"
            end
            sleep 1
          end
        end

        raise "Did not find #{entry[:fqdn]} in Chef index after 180 seconds!"
      end

      def ridley
        @ridley ||= Dir.chdir(repo_dir) { Ridley.from_chef_config }
      end
    end
  end
end
