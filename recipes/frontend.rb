#
# Cookbook Name:: qa-chef-server-cluster
# Recipes:: frontend
#
# Author: Patrick Wright <patrick@chef.io>
# Copyright (C) 2015, Chef Software, Inc. <legal@getchef.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'qa-chef-server-cluster::node-setup'

install_chef_server_core

# TODO: (jtimberman) Replace this with partial search.
chef_servers = search('node', 'chef-server-cluster_role:backend').map do |server| #~FC003
  {
    :fqdn => server['fqdn'],
    :ipaddress => server['ipaddress'],
    :bootstrap => server['chef-server-cluster']['bootstrap']['enable'],
    :role => server['chef-server-cluster']['role']
  }
end

chef_servers << {
               :fqdn => node['fqdn'],
               :ipaddress => node['ipaddress'],
               :role => 'frontend'
              }

node.default['chef-server-cluster'].merge!(node['qa-chef-server-cluster']['chef-server'])

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :chef_server_config => node['chef-server-cluster'],
            :topology => node['qa-chef-server-cluster']['topology'],
            :chef_servers => chef_servers,
            :ha_config => node['ha-config']
  notifies :run, 'execute[add hosts entry]'
  sensitive true
end

chef_server_ingredient 'chef-server-core' do
  action :reconfigure
end

install_opscode_manage

# TODO (pwright) Run again for all I care!!!  Not really.  Temp hack for lack of dns
execute 'add hosts entry' do
  command "echo '#{node['ipaddress']} #{node['qa-chef-server-cluster']['chef-server']['api_fqdn']}' >> /etc/hosts"
  action :nothing
end

# TODO check this out from chef-server cookbook
# ruby_block 'ensure node can resolve API FQDN' do
#   extend ChefServerCoobook::Helpers
#   block { repair_api_fqdn }
#   only_if { api_fqdn_node_attr }
#   not_if { api_fqdn_resolves }
# end
