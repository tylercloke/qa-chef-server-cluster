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

repo_knife_file = File.join(path, '.chef/knife.rb')

execute 'chef exec rake prep' do
  cwd path
end

# TODO: how do we make sure we don't leave any nodes spun up

# rubocop:disable LineLength
ruby_block 'see if cache exists' do
  block do
    puts ''
    Dir.chdir path
    nodes = JSON.parse(Mixlib::ShellOut.new('aws ec2 describe-instances --filters "Name=tag-value,Values=qa-chef-server-cluster-delivery-builder" "Name=tag-value,Values=standalone"').run_command.stdout)
    nodes['Reservations'].each do |reservation|
      reservation['Instances'].each do |instance|
        if Time.now - Date.parse(instance['LaunchTime']).to_time > (24 * 60 * 60)
          puts instance['InstanceId']
        end
      end
    end
  end
end

ruby_block 'stand-up-machine' do
  block do
    Dir.chdir path
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::standalone-server", live_stream: STDOUT, timeout: 7200)
  end
end

ruby_block 'run-pedant' do
  block do
    begin
      node.run_state['pedant_success'] = true
      Dir.chdir path
      shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::standalone-server-test", live_stream: STDOUT, timeout: 7200)
    rescue
      node.run_state['pedant_success'] = false
      Chef::Log.fatal 'Pedant Failed!'
    end
  end
  # Cannot, for the life of me, get 'notifies' to send message on pedant failure,
  # so we will ignore failure and exit success or failure after machine is destroyed.
  ignore_failure true
end

ruby_block 'destroy-machine' do
  block do
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::standalone-server-destroy", live_stream: STDOUT, timeout: 7200)
  end
  action :run
end

ruby_block 'Fail if Pedant Failed' do
  block do
    Chef::Application.fatal!('Pedant failed!', 1)
  end
  not_if { node.run_state['pedant_success'] }
end

# rubocop:enable LineLength
