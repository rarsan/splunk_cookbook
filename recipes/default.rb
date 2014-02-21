#
# Cookbook Name:: splunk_new
# Recipe:: default
#
# Copyright 2013, BBY Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

splunk "#{node['splunk']['version']}-#{node['splunk']['build']}" do
  deploy_dashboards node['splunk']['deploy_dashboards']
  distributed_search node['splunk']['distributed_search']
  install_type node['splunk']['install_type']
  scripted_auth node['splunk']['scripted_auth']
  ssl_forwarding node['splunk']['ssl_forwarding']
  use_license_master node['splunk']['use_license_master']
  web_ssl node['splunk']['web_ssl']
  action :install
end
