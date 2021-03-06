#
# Cookbook Name:: qa-chef-server-cluster
# Recipes:: backend
#
# Author: Joshua Timberman <joshua@getchef.com>
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

# TODO: (jtimberman) Replace this with partial_search.
chef_servers = search('node', 'chef-server-cluster_role:backend').map do |server| #~FC003
  {
    :fqdn => server['fqdn'],
    :ipaddress => server['ipaddress'],
    :bootstrap => server['chef-server-cluster']['bootstrap']['enable'],
    :role => server['chef-server-cluster']['role']
  }
end

# If we didn't get search results, then populate with ourself (we're
# bootstrapping after all)
if chef_servers.empty?
  chef_servers = [
                  {
                    :fqdn => node['fqdn'],
                    :ipaddress => node['ipaddress'],
                    :bootstrap => true,
                    :role => 'backend'
                  }
                 ]
end

node.default['chef-server-cluster'].merge!(node['qa-chef-server-cluster']['chef-server'])

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :chef_server_config => node['chef-server-cluster'],
            :topology => node['qa-chef-server-cluster']['topology'],
            :chef_servers => chef_servers,
            :ha_config => node['ha-config']
  sensitive true
end

chef_server_ingredient 'chef-server-core' do
  action :reconfigure
end

file '/etc/opscode/pivotal.pem' do
  mode 00644
  # without this guard, we create an empty file, causing bootstrap to
  # not actually work, as it checks the presence of this file.
  only_if { ::File.exists?('/etc/opscode/pivotal.pem') }
  subscribes :create, 'chef_server_ingredient[chef-server-core]'
end
