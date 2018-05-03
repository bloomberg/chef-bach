# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: default
# Copyright 2018, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance witsh the License.
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
include_recipe 'ambari_metrics::ambari_metrics_ams_user'
include_recipe 'ambari::ambari_repo_setup'
include_recipe 'ambari_metrics::ambari_metrics_collector'
include_recipe 'ambari_metrics::ambari_metrics_monitor'
include_recipe 'ambari_metrics::ambari_metrics_grafana'
