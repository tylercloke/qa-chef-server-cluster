#
# Cookbook Name:: build
# Attributes:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_attribute 'delivery-red-pill'

# By including this recipe we trigger a matrix of acceptance envs specified
# in the node attribute node['delivery-red-pill']['acceptance']['matrix']
if node['delivery']['change']['stage'] == 'acceptance'
  default['delivery-red-pill']['acceptance']['matrix'] = ['standalone_clean_aws']
end
