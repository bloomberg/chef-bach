#
# Cookbook :: ambari
# Libarary :: utils
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

def ambari_request_header
  admin_password = node['ambari']['admin']['password']
  admin_user = node['ambari']['admin']['user']
  headers = { 'AUTHORIZATION' =>
    "Basic #{Base64.encode64("#{admin_user}:#{admin_password}")}",
              'Content-Type' => 'application/data',
              'X-Requested-By' => 'ambari' }
  headers
end

def view_installed?(view_url)
  Chef::Log.info("View URL:#{view_url}")
  Chef::HTTP.new(node['ambari']['ambari_views_url']).get(view_url, ambari_request_header)
  return true
rescue Net::HTTPServerException
  Chef::Log.info('View seems not created')
  return false
end

def update_default_ambari_admin_password(number_retry: 0, max_retries: 24, delay: 5)
  number_retry += 1
  ambari_base_url = node['ambari']['ambari_server_base_url']
  view_list_url = 'api/v1/views'
  psswd_update_url = 'api/v1/users/username'
  default_password = node['ambari']['admin']['default_password']
  admin_password = node['ambari']['admin']['password']
  admin_user = node['ambari']['admin']['user']

  passwd_update_json = { 'Users' =>
    { 'user_name' => admin_user, 'old_password' => default_password,
      'password' => admin_password } }.to_json
  Chef::HTTP.new(ambari_base_url).get(view_list_url, ambari_request_header)
rescue Net::HTTPServerException => e
  case e.response.code
  when '403'
    headers = ambari_request_header
    headers['AUTHORIZATION'] =
      "Basic #{Base64.encode64("#{admin_user}:#{default_password}")}"

    Chef::HTTP.new(ambari_base_url).put(psswd_update_url, passwd_update_json,
                                        headers)
  else
    unless number_retry >= max_retries
      sleep delay
      retry
    end
  end
rescue => e
  Chef::Log.warn("password update error #{e}")
  unless number_retry >= max_retries
    sleep delay
    retry
  end
end
