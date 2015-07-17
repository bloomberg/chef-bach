
require 'singleton'
require 'pp'
require 'etc'

require 'chef'
require 'chef/version'
require 'chef/client'
require 'chef/config'
require 'chef/config_fetcher'

require 'chef/shell/shell_session'
require 'chef/shell/ext'
require 'chef/json_compat'

# load chef configuration for the node
module LoadNodeContext
   
   class << self
     attr_accessor :client_type
     attr_accessor :options
     attr_accessor :env
     attr_writer   :editor
   end

   def self.start
     setup_logger

     parse_opts
     Chef::Config[:shell_config] = options.config
   end

   def self.setup_logger
     Chef::Config[:log_level] ||= :warn
     Chef::Config[:log_level] = :warn if Chef::Config[:log_level] == :auto
     Chef::Log.init(STDERR)
     Mixlib::Authentication::Log.logger = Ohai::Log.logger = Chef::Log.logger
     Chef::Log.level = Chef::Config[:log_level] || :warn
   end

   def self.client_type
     type = Shell::StandAloneSession
   end

   def self.parse_opts
     @options = Options.new
     @options.parse_opts
   end

   class Options
     include Mixlib::CLI
     def parse_opts
       remainder = parse_options
       environment = remainder.first
       config[:config_file] = ".chef/knife.rb"
       config_msg = config[:config_file] || "none (standalone session)"
       puts "loading configuration: #{config_msg}"
       Chef::Config.from_file(config[:config_file]) if !config[:config_file].nil? && File.exists?(config[:config_file]) && File.readable?(config[:config_file])
       Chef::Config.merge!(config)
     end
   end
end
