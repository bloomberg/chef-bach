# This is a module for a RP that can run update-alternatives
# This makes sure that /etc/alternatives is set correctly
class Chef
  # wrapper for nested class
  class Resource
    # This is the resource class for the provider.  It contains the declaration
    class BachHivePoiseAlternatives < Chef::Resource
      include Poise
      actions(:create)
      attribute(:component, :kind_of => String)
      attribute(:link_name, :kind_of => String)
    end
  end
  # This is the Provider class for the RP.  It contains the implementation
  class Provider
    # This is the Provider class for the RP.  It contains the implementation
    class BachHivePoiseAlternatives < Chef::Provider
      include Poise

      def check_status(c)
        failmsg = "command failed: #{c.stdout}, #{c.stderr}"
        raise failmsg unless c.status.success?
        c.exitstatus
      end

      def run_command(command)
        c = Mixlib::ShellOut.new(command)
        c.run_command
        check_status(c)
      end

      def install_alternatives
        run_command('update-alternatives --install' \
                    " /etc/#{new_resource.component}/conf " \
        " #{new_resource.component}-conf " \
          " /etc/#{new_resource.component}/conf.#{new_resource.link_name} 50")
      end

      def update_alternatives
        run_command('update-alternatives --set ' \
                    " #{new_resource.component}-conf " \
                    "/etc/#{new_resource.component}/"\
                    "conf.#{new_resource.link_name}"
                   )
      end

      def action_create
        notifying_block do
          install_alternatives
          update_alternatives
        end
      end
    end
  end
end
