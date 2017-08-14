require 'mixlib/shellout'

module ChefBach
  class ChefClient
    def initialize(chef_env, vm_entry)
      @chef_env = chef_env
      @vm_entry = vm_entry
    end

    def kill
      puts 'Stopping chef-client'
      [
        'service chef-client stop ',
        'pkill -f chef-client'
      ].each do |command|
        c = Mixlib::ShellOut.new('./nodessh.sh',
                                 @chef_env,
                                 @vm_entry[:hostname],
                                 command,
                                 'sudo')
        c.run_command
      end
      confirm_down
      puts 'Chef client is down'
    end

    def confirm_down
      #
      # If it takes more than 2 minutes
      # something is really broken.
      #
      # This will make 30 attempts with a 1 minute sleep between attempts,
      # or timeout after 31 minutes.
      #
      command = 'ps -ef | grep chef-client | grep -v grep'
      Timeout.timeout(120) do
        max = 5
        1.upto(max) do |idx|
          c = Mixlib::ShellOut.new('./nodessh.sh',
                                   @chef_env,
                                   @vm_entry[:hostname],
                                   command)
          c.run_command
          if c.exitstatus == 1 && c.stdout == ''
            puts 'chef client is down'
            break
          else
            puts "Waiting for chef to go down (attempt #{idx}/#{max})"
            sleep 30
          end
        end
      end
    end
  end
end
