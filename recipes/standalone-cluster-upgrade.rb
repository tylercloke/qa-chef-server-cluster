include_recipe 'qa-chef-server-cluster::_cluster-setup'

machine 'standalone' do
  recipe 'qa-chef-server-cluster::_standalone-provision-upgrade'
  action :converge
end