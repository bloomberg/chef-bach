# create_dirs.rb
# -------
# Creates HDFS directories and manages quota (if applicable)
# Run this in an HBase jruby shell
# -------
# General usage:
# hbase shell create_dirs.rb home_dir dirinfo_file

include Java

require 'yaml'

import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.fs.Path
import org.apache.hadoop.fs.permission.FsPermission
import org.apache.hadoop.hdfs.protocol.HdfsConstants

usage = "hbase shell #{$FILENAME} home_dir dirinfo_file"
banner = "usage: #{usage}\n  -- need "

config = {
  'home' => (ARGV[0] or raise "#{banner} home_dir"),
  'dirinfo_file' => (ARGV[1] or raise "#{banner} dirinfo_file")
}

# hdfs file system handle
fs = FileSystem.newInstance(Configuration.new)

# create home directory
path = Path.new(config['home'])
fs.mkdirs(path)
fs.setOwner(path, 'hdfs', 'hdfs')
fs.setPermission(path, FsPermission.new(0775))

# load and parse dirinfo from file
dirinfo = YAML.load_file(config['dirinfo_file'])
dirinfo.each_pair do |dir, info|
  path = Path.new("#{config['home']}/#{dir}")
  puts "updating path: #{path}"

  # enforce ownership and permissions
  owner = info[:owner]
  group = info[:groups]
  perms = FsPermission.new(info[:perms].to_i(8))

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
    s = s.to_s.downcase
    prefixes = {
      ''  => 1,
      'k' => 1024,
      'm' => 1024**2,
      'g' => 1024**3,
      't' => 1024**4,
      'p' => 1024**5
    }

    base = s[/[0-9.]*/].to_i
    prefix = prefixes[s[/[kmgtp]/] || '']

    base * prefix
  end

  # set space and namespace quotas
  max_quota = HdfsConstants::QUOTA_RESET

  space_quota =
    if info[:space_quota] == 'NO_QUOTA'
      max_quota
    else
      string2long(info[:space_quota])
    end

  ns_quota =
    if info[:ns_quota] == 'NO_QUOTA'
      max_quota
    else
      string2long(info[:ns_quota])
    end

  fs.setQuota(path, ns_quota, space_quota)
end

exit
