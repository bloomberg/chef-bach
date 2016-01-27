
module Bcpc_Hadoop
  module Helper

    include Chef::Mixin::ShellOut

    # Getent Interaction Function
    #
    # type  - Symbol of database type to find in (e.g. :passwd, :group)
    # group - String of entry to search
    #
    # Returns hash of string object names found
    #
    # Raises KeyError on any entry not found
    # Raises RuntimeError on any unspecified error
    #
    def getent(db, entry)
      fields = {:passwd => ['username', 'password', 'UID', 'GID', 'GECOS', 'home dir', 'shell'],
                :group => ['name', 'password', 'GID', 'members']}

      # query the lookup type here to raise if passed an invalid type
      lookup_fields = fields[db] or raise TypeError, "Unknown database #{db}"

      # expected raw output will be akin to:
      # cwb@clay-machine:~$ getent passwd root
      # root:x:0:0:root:/root:/bin/sh
      # cwb@clay-machine:~$ getent group adm
      # adm:x:4:syslog,cwb
      cmd = shell_out!("getent #{db} #{entry}", {:returns => [0, 2]})

      # raise for any error other than not finding entries (usually an exit(1))
      raise cmd.stderr if !cmd.stderr.empty?
      # getent returns nothing if the entry is not found but has a return code of 2
      raise KeyError, "Unable to find key #{entry} in getent DB #{db}" if cmd.exitstatus == 2

      getent_fields = cmd.stdout.strip.split(':')
      response = Hash[lookup_fields.zip(getent_fields)]

      # parse the members for a group query
      if db == :group
        # return an empty string if no members(nil)
        response['members'] = "" unless response['members']
        # split the members into an array of strings
        response['members'] = response['members'].split(',')
      end

      response
    end
  end
end
