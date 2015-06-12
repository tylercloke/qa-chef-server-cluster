#
# Cookbook Name:: build
# Recipe:: provision_tier_clean_aws
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
# rubocop:disable LineLength

repo_knife_file = File.join(path, '.chef/knife.rb')

ruby_block 'stand-up-machine' do
  block do
    Dir.chdir path
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster", live_stream: STDOUT, timeout: 7200)
  end
end

ruby_block 'run-pedant' do
  block do
    begin
      node.run_state['pedant_success'] = true
      Dir.chdir path
      shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster-test", live_stream: STDOUT, timeout: 7200)
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
    shell_out!("chef exec bundle exec chef-client --force-formatter -z -p 10257 -j #{attributes_file} -c #{repo_knife_file} -o qa-chef-server-cluster::tier-cluster-destroy", live_stream: STDOUT, timeout: 7200)
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
