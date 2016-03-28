
module Bcpc_Hadoop
  module Helper

    include Chef::Mixin::ShellOut

    # Groups Interaction Function
    #
    # user - String of user entry for which to search
    #
    # Returns hash of string object group names found
    #
    # Raises KeyError on any entry not found
    # Raises RuntimeError on any unspecified error
    #
    def groups(user)
      # expected raw output will be akin to:
      # cwb@clay-machine:~$ groups foobar
      # groups: foobar: no such user
      # cwb@clay-machine:~$ groups cwb
      # cwb : adm cdrom sudo dip plugdev lpadmin sambashare
      # cwb@clay-machine:~$ groups yarg
      # yarg : groups: cannot find name for group ID 666
      # 666 groups: cannot find name for group ID 991
      # 991
      # note stdout: "yarg : 666 991" the rest is stderr
      cmd = shell_out!("groups #{user}", {:returns => [0, 1]})

      # raise for not finding a user with stderr "groups: foobar: no such user"
      raise KeyError, cmd.stderr if cmd.stderr.include?("#{user}: no such user")
      # raise except for errors with stderr "cannot find name for group ID ###"
      raise cmd.stderr if !cmd.stderr.empty? unless cmd.stderr.each_line.map{ |l| l.match(/cannot find name for group ID [0-9]*/) }.all?

      (returned_user, groups) = cmd.stdout.strip.split(' : ')
      groups.split()
    end
  end
end
