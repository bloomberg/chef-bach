module Bcpc_Hadoop
  module Helper
    require 'yaml'
    include Chef::Mixin::ShellOut

    # Writes a spool yaml file of directory creation information.
    # Calls the JRuby directory creation script with the spool file.
    #
    # @param [String] base_dir 
    #   parent directory to generate directories in.
    # @param [Hash] default
    #   default dir_creation parameters
    #   owner: default owner for directories
    #   group: default group for directories
    #   perms: default permissions for directories
    #   space_quota: default space_quota for directories
    #   ns_quota: default namespace quota for directories
    # @param [Hash] dirinfo 
    #   Hash of dir_creation entries
    def dir_creation(base_dir='/tmp', defaults={}, dirinfo={})
      file_cache = File.join(
        Chef::Config[:file_cache_path],
        'cookbooks/bcpc-hadoop',
        'files/default'
      )

      # path to creation script and caches
      strategy = File.basename(base_dir)
      jruby_script = File.join(file_cache, 'create_dirs.rb')
      dirinfo_cache = File.join(file_cache, "#{strategy}_dirinfo.yml")
      puts "\n#{strategy}_dir_creation(#{dirinfo.size}): #{dirinfo.keys.to_a}"

      # Build dirinfo cache
      # -------------------
      # use default space/ns quota if dir-specific quota unset
      dirinfo_hash = dirinfo.map do |dir, info|
        info = {
          owner: info['owner'] || defaults['owner'],
          group: info['group'] || defaults['group'],
          perms: info['perms'] || defaults['perms'],
          space_quota: info['space_quota'] || defaults['space_quota'],
          ns_quota: info['ns_quota'] || defaults['ns_quota']
        }
        [dir, info]
      end.to_h

      # Save dirinfo cache
      File.open(dirinfo_cache, 'w+') { |f| f.puts(dirinfo_hash.to_yaml) }

      # allow the hdfs user to read them
      File.chmod(0o0644, jruby_script)
      File.chmod(0o0644, dirinfo_cache)

      # execute the jruby script
      jruby_shell_cmd = "hbase shell #{jruby_script} #{base_dir} #{dirinfo_cache}"
      jruby_shell =
        Mixlib::ShellOut.new(jruby_shell_cmd, user: 'hdfs', timeout: 120)
      jruby_shell.run_command
      jruby_shell.error!
    end
  end
end
