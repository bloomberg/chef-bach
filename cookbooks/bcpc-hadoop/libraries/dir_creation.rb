module Bcpc_Hadoop
  module Helper
    require 'yaml'
    include Chef::Mixin::ShellOut

    def dir_creation(mode)
      file_cache = File.join(
        Chef::Config[:file_cache_path],
        'cookbooks/bcpc-hadoop',
        'files/default'
      )

      # path to creation script and caches
      jruby_script = File.join(file_cache, 'create_dirs.rb')
      dirinfo_cache = File.join(file_cache, "#{mode}_dirinfo.yml")

      # dir creation configuration attributes
      dirinfo = node['bcpc']['hadoop']['hdfs'][mode]['dirinfo']
      home = node['bcpc']['hadoop']['hdfs'][mode]['home']
      puts "\n#{mode}_dir_creation(#{dirinfo.size}): #{dirinfo.keys.to_a}"

      # Build dirinfo cache
      # -------------------
      # use default space/ns quota if dir-specific quota unset
      dirinfo_hash = dirinfo.map do |dir, info|
        [
          dir,
          {
            owner: info['owner'] ||
              node['bcpc']['hadoop']['hdfs'][mode]['owner'],
            group: info['group'] ||
              node['bcpc']['hadoop']['hdfs'][mode]['group'],
            perms: info['perms'] ||
              node['bcpc']['hadoop']['hdfs'][mode]['perms'],
            space_quota: info['space_quota'] ||
              node['bcpc']['hadoop']['hdfs']["#{dir}_space_quota"] ||
              node['bcpc']['hadoop']['hdfs'][mode]['space_quota'],
            ns_quota: info['ns_quota'] ||
              node['bcpc']['hadoop']['hdfs']["#{dir}_ns_quota"] ||
              node['bcpc']['hadoop']['hdfs'][mode]['ns_quota']
          }
        ]
      end.to_h

      # Save dirinfo cache
      File.open(dirinfo_cache, 'w+') { |f| f.puts(dirinfo_hash.to_yaml) }

      # allow the hdfs user to read them
      File.chmod(0o0644, jruby_script)
      File.chmod(0o0644, dirinfo_cache)

      # execute the jruby script
      jruby_shell_cmd = "hbase shell #{jruby_script} #{home} #{dirinfo_cache}"
      jruby_shell =
        Mixlib::ShellOut.new(jruby_shell_cmd, user: 'hdfs', timeout: 120)
      jruby_shell.run_command
      jruby_shell.error!
    end
  end
end
