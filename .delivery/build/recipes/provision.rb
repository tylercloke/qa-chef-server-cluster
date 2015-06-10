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

cookbook_file "attributes.json" do
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

# template File.join(path, 'data_bags/secrets/lob-user-key.json') do
#   sensitive true
#   source 'lob-user-key.json.erb'
#   variables(
#     private_key_path: ssh_private_key_path,
#     public_key_path:  ssh_public_key_path
#   )
# end

repo_knife_file = File.join(path, ".chef/knife.rb")

execute "chef exec rake prep" do
  cwd path
end

# TODO how do we make sure we don't leave any nodes spun up

ruby_block "stand-up-machine" do
  block do
    Dir.chdir path
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster", {:live_stream => STDOUT})
  end
end

ruby_block "run-pedant" do
  block do
    Dir.chdir path
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster-test", {:live_stream => STDOUT})
  end
  notifies :run, 'ruby_block[destroy-machine]', :delayed
end

ruby_block "destroy-machine" do
  block do
    Dir.chdir path
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster-destroy", {:live_stream => STDOUT})
  end
  action :nothing
end



