#
# Cookbook Name:: build
# Recipe:: provision
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

delivery_secrets = get_project_secrets
path             = node['delivery']['workspace']['repo']
cache            = node['delivery']['workspace']['cache']

ssh_private_key_path =  File.join(cache, '.ssh', 'chef-server-build-key')
ssh_public_key_path  =  File.join(cache, '.ssh', 'chef-server-build-key.pub')

directory File.join(cache, '.ssh')
directory File.join(cache, '.aws')

file ssh_private_key_path do
  sensitive true
  content delivery_secrets['private_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0600'
end

file ssh_public_key_path do
  content delivery_secrets['public_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0644'
end

template File.join(cache, '.aws/config') do
  sensitive true
  source 'aws-config.erb'
  variables(
    aws_access_key_id: delivery_secrets['access_key_id'],
    aws_secret_access_key: delivery_secrets['secret_access_key'],
    region: delivery_secrets['region']
  )
end

ruby_block 'public' do
  block do
    Chef::Log.fatal File.read(ssh_public_key_path)
  end
end

ruby_block 'private' do
  block do
    Chef::Log.fatal File.read(ssh_private_key_path)
  end
end

ruby_block 'aws' do
  block do
    Chef::Log.fatal File.read(File.join(cache, '.aws/config'))
  end
end
