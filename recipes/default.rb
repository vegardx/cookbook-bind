#
# Cookbook Name:: bind
# Recipe:: default
#

# Determin if this is a slave or master
if node.roles.include?('NS-master')
  peers = search('node', 'role:NS-slave')
else
  peers = search('node', 'role:NS-master')
end

# Install packages and set up services
package 'bind9' do
  action :install
end

service 'bind9' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :start ]
end

# Generate configuration
zones = Array.new
bag = data_bag('zones')

bag.each do |zone|
  zones << data_bag_item('zones', zone)
end

template "/etc/bind/named.conf.options" do
	source "named.conf.options.erb"
	notifies :restart, "service[bind9]", :immediately
end

template "/etc/bind/named.conf.local" do
	source "named.conf.local.erb"
  variables :zones => zones, :peers => peers
  notifies :reload, "service[bind9]", :immediately
end
