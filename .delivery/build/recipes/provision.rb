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

attributes_file = File.join(cache, 'attributes.json')

cookbook_file 'attributes.json' do
  path attributes_file
  action :create
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

# TODO: support for other keys in qa-chef-server-cluster cookbook
#
# template File.join(path, 'data_bags/secrets/lob-user-key.json') do
#   sensitive true
#   source 'lob-user-key.json.erb'
#   variables(
#     private_key_path: ssh_private_key_path,
#     public_key_path:  ssh_public_key_path
#   )
# end

execute 'chef exec rake prep' do
  cwd path
end

# TODO: how do we make sure we don't leave any nodes spun up

# rubocop:disable LineLength
ruby_block 'Cleanup AWS instances' do
  block do
    puts ''
    Dir.chdir path
    nodes = JSON.parse(Mixlib::ShellOut.new('aws ec2 describe-instances --filters "Name=tag-value,Values=qa-chef-server-cluster-delivery-builder"').run_command.stdout)
    nodes['Reservations'].each do |reservation|
      reservation['Instances'].each do |instance|
        if Time.now - Date.parse(instance['LaunchTime']).to_time > (24 * 60 * 60)
          Chef::Log.warn "Terminating EC2 Instance #{instance['InstanceId']} which has been running since #{instance['LaunchTime']}"
          Mixlib::ShellOut.new("aws ec2 terminate-instances --instance-ids #{instance['InstanceId']}").run_command
        end
      end
    end
  end
end
# rubocop:enable LineLength

include_recipe 'delivery-red-pill::provision'
