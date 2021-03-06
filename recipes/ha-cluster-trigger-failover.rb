#
# Cookbook Name:: qa-chef-server-cluster
# Recipes:: ha-trigger-failover
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

include_recipe 'qa-chef-server-cluster::provisioner-setup'

# make sure the primary server is fully running before we stop keepalived
machine 'bootstrap-backend' do
  run_list [ 'qa-chef-server-cluster::chef-server-readiness' ]
end

machine_execute 'chef-server-ctl stop keepalived' do
  machine 'bootstrap-backend'
end

machine_batch do
  machine 'bootstrap-backend' do
    run_list [ 'qa-chef-server-cluster::ha-verify-backend-backup' ]
  end
  machine 'secondary-backend' do
    run_list [ 'qa-chef-server-cluster::ha-verify-backend-master' ]
  end
end
