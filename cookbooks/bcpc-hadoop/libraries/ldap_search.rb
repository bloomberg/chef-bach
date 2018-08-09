# ldap_search.rb
# Routines for querying the LDAP server

module Bcpc_Hadoop::Helper
  class LDAPSearch
    include Chef::Mixin::ShellOut
    # Initialize LDAPSearch
    # host - LDAP Host to query
    # port - LDAP Port to query
    # user - Principal to use for simple authentication
    # password - Password to use for simple authentication
    # base_dn - DN to begin search from
    # roles_dn - DN to search for role accounts from
    def initialize(config)
      @host = config[:host]
      @port = config[:port]

      @user = config[:user]
      @password = config[:password]

      @base_dn = config[:base_dn]
      @roles_dn = config[:roles_dn]
    end

    # Find objects in an LDAP group
    # @mode: Symbol of object type to find for (e.g. :user, :role, :group)
    # @group: fully distinguished group DN to find objects for
    # @attr: String of attribute to find (e.g. "sAMAccountName" or "dn")
    #
    # Returns Array of string object names found
    # Raises RuntimeError on any unspecified error
    def group_search(mode, group, attr = 'sAMAccountName')
      strategy = {
        role: "'(&" \
          "(objectClass=user)" \
          "(!(objectClass=computer))" \
          "(memberOf=%{group})" \
          "(|(memberOf=#{@roles_dn})(!(employeeID=*)))" \
        ")'",
        user: "'(&" \
          "(objectClass=user)" \
          "(!(objectClass=computer))" \
          "(employeeID=*)" \
          "(memberOf=%{group})" \
        ")'",
        group: "'(&" \
          "(objectClass=group)" \
          "(memberOf=%{group})" \
        ")'"
      }

      ldap_filter = strategy[mode] or raise TypeError,
        "Unknown search strategy: #{mode}. valid options: #{strategy.keys}"

      auth = (@user && @password && "-D '#{@user}' -w #{@password}")
      ldap_search = "ldapsearch -LLL -o ldif-wrap=no -E pr=1000/noprompt " \
        "-h #{@host} -p #{@port} -b '#{@base_dn}' #{auth} " \
        "#{ldap_filter} %{attr} "

      return shell_out!(ldap_search % {
        group: group,
        attr: attr,
      }).stdout.split("\n").reduce([]) do |acc, curr|
        object = curr[/^#{attr}: (.*)/, 1]
        object ? acc.push(object) : acc
      end
    end
  end
end
