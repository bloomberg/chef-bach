# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: ambari_metrics_grafana
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
include_recipe 'ambari::ambari_server_install'

grafana_datasource 'bach-ams-collector' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  datasource(
    type: 'ambarimetrics',
    url: node['ams']['collector']['url'],
    access: 'proxy',
    isdefault: true
  )
end

node['ams']['grafana']['dashboards'].keys.each do |dashboard_key|
  grafana_dashboard dashboard_key do
    host node['ams']['metrics_grafana']['host']
    port node['ams']['metrics_grafana']['port']
    admin_user node['ams']['metrics_grafana']['admin_user']
    admin_password node['ams']['metrics_grafana']['admin_password']
    dashboard(path: node['ams']['grafana']['dashboards'][dashboard_key],
              overwrite: true)
  end
end
