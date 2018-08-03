module Bcpc_Hadoop
  module Helper
    require 'yaml'
    include Chef::Mixin::ShellOut

    def dir_creation(mode, dirs, home, perms)
      file_cache = File.join(
        Chef::Config[:file_cache_path],
        'cookbooks/bcpc-hadoop',
        'files/default'
      )

      # path to creation script and caches
      jruby_script = File.join(file_cache, 'dirs.rb')
      dir_cache = File.join(file_cache, "#{mode}_list")
      quota_cache = File.join(file_cache, "#{mode}_quotas.yml")

      # save dir cache
      File.open(dir_cache, 'w+') { |f| f.puts(dirs) }
      puts "dir cache(#{dirs.length}): #{dirs}"

      # build quota cache
      quotas = dirs.map do |dir|
        quota =
          # use default quota if dir-specific quota unset
          node['bcpc']['hadoop']['hdfs'][mode]["#{dir}_space_quota"] ||
          node['bcpc']['hadoop']['hdfs'][mode]['space_quota']
        [dir, quota]
      end.to_h

      # save quota cache
      File.open(quota_cache, 'w+') { |f| f.puts(quotas.to_yaml) }

      # allow the hdfs user to read them
      File.chmod(0644, jruby_script)
      File.chmod(0644, dir_cache)
      File.chmod(0644, quota_cache)

      # execute the jruby script
      jruby_shell = "hbase shell #{jruby_script} "\
        "#{mode} #{dir_cache} #{quota_cache} #{home} #{perms}"
      jruby_shell = Mixlib::ShellOut.new(jruby_shell, user: 'hdfs', timeout: 120)
      jruby_shell.run_command
      jruby_shell.error!
    end
  end
end
