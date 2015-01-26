#
# Cookbook Name:: bcpc_jmxtrans
# Library:: utils
#
# Copyright 2013, Bloomberg Finance L.P.
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

require 'date'
#
# To determine whether a process need to be restarted since a dependent
# process got restarted.
# Input parameters: process_name - name of the process to be restarted
# process_cmd - command of the process which can be used to identify the PID
# dep_process_cmds - hash of process_name as key and the corresponding process command as value
#
def process_require_restart?(process_name, process_cmd, dep_process_cmds)
  #
  # Code to retrieve the start time of target process
  #
  target_process_pid = `pgrep -f #{process_cmd}`
  if target_process_pid != ""
    target_process_stime = `ps --no-header -o lstart #{target_process_pid}`
  else
    Chef::Log.info "#{process_name} is not currently running which was the expected state"
    return true
  end
  #
  # Code to compare the start times and return whether the target processes need to be restarted
  #
  ret = false
  restarted_processes = Array.new
  dep_process_cmds.each do |dep_process, dep_process_cmd|
    dep_process_pids = `pgrep -f #{dep_process_cmd}` 
    if dep_process_pids != ""
      dep_process_pids_arr = dep_process_pids.split("\n")
      dep_process_pids_arr.each do |dep_process_pid| 
        dep_process_stime = `ps --no-header -o lstart #{dep_process_pid}`
        if DateTime.parse(target_process_stime) < DateTime.parse(dep_process_stime)
          restarted_processes.push(dep_process)
          ret = true
        end
      end
    end
  end
  if ret
    Chef::Log.info "#{process_name} service needs restart since #{restarted_processes.join(",")} process(s) got restarted"
  end
  return ret
end
