#
# oozie_client.rb
# ruby client for oozie
#
# Copyright 2018, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Oozie
  class ClientV1
    attr_accessor :host, :port, :user

    def initialize(oozie_url='http://localhost:11000/oozie', user='oozie')
      @oozie = oozie_url 
      @user = user
    end

    def jobs(filter={}, jobtype='workflow', len=10)
      execute('jobs', user, {
        oozie: @oozie,
        jobtype: jobtype,
        filter: "\"#{filter_string(filter)}\"",
        len: len
      })
    end

    def kill_jobs(filter={}, jobtype='workflow', len=1000)
      execute('jobs', user, {
        oozie: @oozie,
        jobtype: jobtype,
        filter: "\"#{filter_string(filter)}\"",
        len: len,
        kill: nil
      })
    end

    def run(config, user=@user)
      execute('job', user, {
        oozie: @oozie,
        config: config,
        run: nil
      })
    end

    def rerun(action_id, config, user=@user)
      execute('job', user, {
        oozie: @oozie,
        config: config,
        rerun: action_id
      })
    end

    def kill(job_id, user=@user)
      execute('job', user, {
        oozie: @oozie,
        kill: job_id
      })
    end

    def get_id(job_name, jobtype='workflow', status='RUNNING')
      jobs_cmd = jobs({ name: job_name, status: status }, 'coordinator', 1)
      match = jobs_cmd.stdout.match(/(\S+)\s+#{job_name}/)
      return match.nil? ? nil : match[1]
    end

    private ## private methods

    def execute(subcommand, user=@user, options={})
      require 'mixlib/shellout'
      command = "oozie #{subcommand} #{options_string(options)}"
      # puts command ## print debug command
      return Mixlib::ShellOut.new(command, user: user, timeout: 90).run_command
    end

    def options_string(options)
      options.map { |key, value| "-#{key.to_s} #{value}" }.join(' ')
    end

    def filter_string(filter)
      filter.map { |key, value| "#{key.to_s}=#{value}" }.join(';')
    end
  end

  class Client < ClientV1
  end
end
