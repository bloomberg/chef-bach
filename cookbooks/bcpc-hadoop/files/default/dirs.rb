# dirs.rb
# creates hdfs dirs
# run this in an hbase jruby shell

# usage: hbase shell dirs.rb [user|groups] dir_file quota_yml home_dir perms
# user ex. hbase shell dirs.rb user /tmp/user_dirs /tmp/user_quotas.yml /user 0700
# group ex. hbase shell dirs.rb groups /tmp/group_dirs /tmp/group_quotas.yml /groups 0770

include Java

require 'yaml'

import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.fs.Path
import org.apache.hadoop.fs.permission.FsPermission
import org.apache.hadoop.hdfs.protocol.HdfsConstants

usage = "hbase shell "\
  "dirs.rb [user|groups] dir_file quota_yml home_dir perms"
banner = "usage: #{usage}\n  -- need "

config = {
  'mode' => (ARGV[0] or raise "#{banner} [user|groups]"),
  'dir_file' => (ARGV[1] or raise "#{banner} dir_file"),
  'quota_file' => (ARGV[2] or raise "#{banner} quota_yml"),
  'home' => (ARGV[3] or raise "#{banner} home_dir"),
  'perms' => (ARGV[4] or raise "#{banner} perms"),
}

# hdfs file system handle
fs = FileSystem.newInstance(Configuration.new)

# create home directory
path = Path.new(config['home'])
fs.mkdirs(path)
fs.setOwner(path, 'hdfs', 'hdfs')
fs.setPermission(path, FsPermission.new(0775))

# load quotas from file
quotas = YAML.load_file(config['quota_file'])

File.open(config['dir_file']) do |f|
  f.each_line do |dir|
    dir = dir.strip
    path = Path.new("#{config['home']}/#{dir}")
    puts "updating path: #{path}"

    # enforce ownership and permissions
    owner = config['mode'] == 'user' ? dir : 'hdfs'
    group = config['mode'] == 'groups' ? dir : 'hdfs'
    perms = FsPermission.new(config['perms'].to_i(8))

    # create the directory
    fs.mkdirs(path)
    fs.setOwner(path, owner, group)
    fs.setPermission(path, perms)

    # Takes a string with a unit-prefix
    # returns the result as a "long"
    # Examples are:
    #   string2long(600) => 600
    #   string2long('1') => 1
    #   string2long('1k') => 1024
    #   string2long('30T') => 32985348833280
    def string2long(s)
      s = s.to_s
      prefixes = {
        ''  => 1,
        'k' => 1024,
        'm' => 1024**2,
        'g' => 1024**3,
        't' => 1024**4,
        'p' => 1024**5
      }

      base = s.sub(/[kmgtp]/, '').to_i
      prefix = prefixes[s.sub(/[0-9.]*/,'').downcase]

      return base * prefix
    end

    # set space quota
    if quotas[dir]
      max_quota = HdfsConstants::QUOTA_DONT_SET
      quota = quotas[dir] == "NO_QUOTA" ?
        (max_quota - 1) : string2long(quotas[dir])
      fs.setQuota(path, max_quota, quota)
    end
  end
end

exit
