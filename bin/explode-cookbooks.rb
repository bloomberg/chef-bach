#!/opt/chefdk/embedded/bin/ruby
#
# bin/explode-cookbooks.rb
#
# This script moves all of the cookbooks in the old chef-bach repo
# into independent git repositories.
#

target_directory = ARGV[0]
unless( !target_directory.nil? && Dir.exists?(target_directory))
  puts "Invalid target directory!"
  puts "usage: ./bin/explode-cookbooks.rb TARGET"
  exit 1
end

bach_upstream = 'https://github.com/bloomberg/chef-bach'

cookbook_destinations = {
                         'bcpc' => 'chef-bach-bcpc',
                         'bcpc-hadoop' => 'chef-bcpc-hadoop',
                         'bcpc_jmxtrans' => 'chef-bcpc_jmxtrans',
                         'hannibal' => 'chef-hannibal',
                         'kafka-bcpc' => 'chef-kafka-bcpc',
                        }

puts "Exploding cookbooks to #{target_directory}"

master_repo_path = target_directory + "/chef-bach"

system("git clone #{bach_upstream} #{master_repo_path}")

delete_from_upstream = lambda do |target_cookbook|
  old_cwd = Dir.pwd
  Dir.chdir(master_repo_path)
  system("git rm -q -r cookbooks/#{target_cookbook}")
  system('git commit -m "Moved ' + target_cookbook + ' into its own repo."')
  Dir.chdir(old_cwd)
end

explode = lambda do |target_cookbook|
  old_cwd = Dir.pwd 
  destination = target_directory + "/" + cookbook_destinations[target_cookbook]
  puts "Exploding #{master_repo_path}/cookbooks/#{target_cookbook} " +
       "into #{destination}"
  system("git clone #{master_repo_path} #{destination}")
  Dir.chdir(destination)
  system("git rm -q `git ls-files | grep -v #{target_cookbook}`")
  system("git mv cookbooks/#{target_cookbook}/* .")
  system("git rm -q -r cookbooks")
  system("rm -r cookbooks")
  system('git commit -m "Moved ' + target_cookbook + ' into its own repo."')
  system("git remote remove origin")
  Dir.chdir(old_cwd)
end

cookbook_destinations.keys.each do |target_cookbook|
  explode.call(target_cookbook)
  delete_from_upstream.call(target_cookbook)
end
