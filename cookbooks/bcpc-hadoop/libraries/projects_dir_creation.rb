module Bcpc_Hadoop
  module Helper
    require 'yaml'
    include Chef::Mixin::ShellOut

    def projects_dir_creation(dirinfo)
      file_cache = File.join(
        Chef::Config[:file_cache_path],
        'cookbooks/bcpc-hadoop',
        'files/default'
      )

      # path to creation script and caches
      jruby_script = File.join(file_cache, 'create_projects_dirs.rb')
      dirinfo_cache = File.join(file_cache, 'dirinfo.yml')

      # Build dirinfo cache
      # -------------------
      # use default space/ns quota if dir-specific quota unset
      dirinfo_hash = dirinfo.map do |dir, info|
        [
          dir,
          {
            owner: info['owner'] ||
              node['bcpc']['hadoop']['hdfs']['projects']['owner'],
            group: info['group'] ||
              node['bcpc']['hadoop']['hdfs']['projects']['group'],
            perms: info['perms'] ||
              node['bcpc']['hadoop']['hdfs']['projects']['perms'],
            space_quota: info['space_quota'] ||
              node['bcpc']['hadoop']['hdfs']['projects']['space_quota'],
            ns_quota: info['ns_quota'] ||
              node['bcpc']['hadoop']['hdfs']['projects']['ns_quota']
          }
        ]
      end.to_h

      # Save dirinfo cache
      File.open(dirinfo_cache, 'w+') { |f| f.puts(dirinfo_hash.to_yaml) }

      # allow the hdfs user to read them
      File.chmod(0o0644, jruby_script)
      File.chmod(0o0644, dirinfo_cache)

      # execute the jruby script
      jruby_shell_cmd = "hbase shell #{jruby_script} #{dirinfo_cache}"
      jruby_shell =
        Mixlib::ShellOut.new(jruby_shell_cmd, user: 'hdfs', timeout: 120)
      jruby_shell.run_command
      jruby_shell.error!
    end
  end
end
