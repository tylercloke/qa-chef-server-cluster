#
# Cookbook Name:: build
# Attributes:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_attribute 'delivery-red-pill'

default['delivery-red-pill']['acceptance']['matrix'] = ['provision_standalone_clean_aws']
