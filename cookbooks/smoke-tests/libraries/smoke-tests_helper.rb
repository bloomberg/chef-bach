# vim: tabstop=2:shiftwidth=2:softtabstop=2 
module HadoopSmokeTests
  module OozieHelper
    def test_oozie_running?(host, user)
      oozie_cmd = "sudo -u #{user} oozie admin -oozie http://#{host}:11000/oozie -status"
      Chef::Log.debug("Running oozie command #{oozie_cmd}")
      cmd = Mixlib::ShellOut.new( oozie_cmd, :timeout => 20).run_command
      Chef::Log.debug("Oozie status: #{cmd.stdout} #{cmd.stderr}")
      cmd.exitstatus == 0 && cmd.stdout.include?('NORMAL')
    end

    def find_working_server(oozie_hosts, user)
      oozie_hosts.select do 
          |oozie_host| test_oozie_running?(oozie_host, user) 
      end
    end

    def submit_workflow(host, user, prop_file)
      oozie_cmd = "sudo -u #{user} oozie job -run -config #{prop_file} -oozie http://#{host}:11000/oozie"
      cmd = Mixlib::ShellOut.new(oozie_cmd, timeout: 20).run_command
      if cmd.exitstatus == 0
        Chef::Log.debug("Job submission result: #{cmd.stdout}")
      else
        # raise exception?
        Chef::Log.error("Job submission result: #{cmd.stderr}")
      end
      cmd.exitstatus
    end

    def submit_workflow_running_host(user, prop_file)
      operational_hosts = 
        find_working_server(node['hadoop_smoke_tests']['oozie_hosts'], user)
      if operational_hosts.length > 0 then
        Chef::Log.debug('Identified live oozie server(s) ' +  operational_hosts.to_s) 
        submit_workflow(operational_hosts[0], user, prop_file)
      else
        Chef::Log.error('Unable to find a live oozie server')
      end
    end
    
    # user -> host -> string
    # if there is nothing else to return we always 
    # return an empty string, this way we can still
    # examine contents and always return one thing
    # while providing a type guarantee of some sort
    def submit_command_running_host(user, command)
      operational_hosts = 
        find_working_server(node['hadoop_smoke_tests']['oozie_hosts'], user)
      if operational_hosts.length > 0 then
        Chef::Log.debug('Identified live oozie server(s) ' +  operational_hosts.to_s) 
        
        oozie_cmd = "sudo -u #{user} oozie #{command} -oozie http://#{operational_hosts[0]}:11000/oozie"
        cmd = Mixlib::ShellOut.new(oozie_cmd, timeout: 20).run_command
        if cmd.exitstatus == 0
          Chef::Log.debug("Command submission result: #{cmd.stdout}")
          cmd.stdout
        else
          # raise exception?
          Chef::Log.error("Command submission result: #{cmd.stderr}")
          nil
        end
      else
        Chef::Log.error('Unable to find a live oozie server')
        nil
      end
    end

  end
end
