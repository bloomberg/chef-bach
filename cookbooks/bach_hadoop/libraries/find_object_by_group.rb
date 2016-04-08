
module Bcpc_Hadoop
  module Helper

    include Chef::Mixin::ShellOut

    # Initialize LDAP
    #
    # keytab - File path location of keytab to use for GSSAPI authentication
    #
    # Post-Condition: Sets necessary module constants needed by
    #                 find_object_by_group()
    def initialize_ldap(keytab, ldap_host)
      self.class.const_set(:FIND_ROLE_ACCOUNT_CMD, "kinit -kt #{keytab} && " \
                     "ldapsearch -LLL -Y GSSAPI -o ldif-wrap=no -h #{ldap_host} -D %{basedn} -b '%{basedn}' " \
                     "'(&(objectClass=user)(!(objectClass=computer))(!(employeeID=*))(|(memberOf=%{group})))' %{attr}")
      self.class.const_set(:FIND_HUMAN_USER_CMD, "kinit -kt #{keytab} && " \
                     "ldapsearch -LLL -Y GSSAPI -o ldif-wrap=no -h #{ldap_host} -D %{basedn} -b 'OU=Enabled Accounts,%{basedn}' " \
                     "'(&(objectClass=user)(!(objectClass=computer))(&(employeeID=*)(|(memberOf=%{group}))))' %{attr}")
      self.class.const_set(:FIND_GROUP_CMD, "kinit -kt #{keytab} && " \
                     "ldapsearch -LLL -Y GSSAPI -o ldif-wrap=no -h #{ldap_host} -D %{basedn} -b '%{basedn}' " \
                     "'(&(objectClass=group)(memberOf=%{group}))' %{attr}")
    end

    # Find objects in an LDAP group
    #
    # type  - Symbol of object type to find for (e.g. :user, :role, :group)
    # group - String of group DN to find objects for
    # attr  - String of attribute to find (e.g. "sAMAccountName" or "dn")
    #
    # Returns Array of string object names found
    #
    # Raises RuntimeError on any unspecified error
    #
    def find_object_by_group(basedn, type, group, attr = "sAMAccountName")

      if ! ( defined?(self.class.const_get(:FIND_HUMAN_USER_CMD)) &&
             defined?(self.class.const_get(:FIND_ROLE_USER_CMD)) &&
             defined?(self.class.const_get(:FIND_GROUP_CMD)) )
        raise "Need to run initialize() before find_object_by_group"
      end

      type_strategy = {:user => self.class.const_get(:FIND_HUMAN_USER_CMD),
                       :role => self.class.const_get(:FIND_ROLE_ACCOUNT_CMD),
                       :group => self.class.const_get(:FIND_GROUP_CMD)}
      # query the lookup type here to raise if passed an invalid type
      lookup_type = type_strategy[type] or raise TypeError, "Unknown type #{type}"

      # expected raw output will be akin to:
      # dn: CN=Dude,OU=Bowlers,OU=Groups,OU=bcpc,DC=example,DC=com
      # memberOf: CN=white-russian_drinkers,OU=Groups,OU=OU=UNIX,DC=bcpc,DC=example,DC=com
      # memberOf: CN=users,OU=Groups,OU=UNIX,DC=bcpc,DC=example,DC=com
      #
      # dn: CN=Walter,OU=Bowlers,OU=Groups,OU=bcpc,DC=example,DC=com
      # memberOf: CN=users,OU=Groups,OU=UNIX,DC=bcpc,DC=example,DC=com
      cmd = shell_out!(lookup_type % {group: group, basedn: basedn, attr: attr}, {:returns => [0]})

      accts = cmd.stdout.each_line.select{ |l| l.start_with?(attr + ":") }

      accts.map{ |l| l.strip.sub(/^#{attr}: /,'') }
    end
  end
end
