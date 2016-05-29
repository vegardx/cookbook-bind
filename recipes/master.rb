#
# Cookbook Name:: bind
# Recipe:: master
#

# Generate zones
zones = data_bag('zones')

zones.each do |item|
  zone = data_bag_item('zones', item)

  # Auto populate zone with hosts based on roles
  unless zone['roles'].nil? || zone['roles'] == ''
    zone['roles'].each do |role|
      search('node', "role:#{role}", :filter_result => { 'hostname' => ['hostname'], 'ipaddress' => ['ipaddress'] }).each do |host|
        next if host['ipaddress'] == '' || host['ipaddress'].nil?
        zone['records'].push( {
          "hostname" => host['hostname'],
          "type" => "A",
          "value" => host['ipaddress']
        })
      end
    end
  end

  # Compute digest of all zone data to see if anything has changed, and roll serial if it has
  sum = String.new
  zone.each do |n|
    sum = sum + n.to_s
  end

  digest = Digest::SHA256.hexdigest(sum)

  # Store current digest on disk, only update zone if it changes
  file "/etc/bind/digest.#{zone['fqdn']}" do
    action :create
    content digest
    notifies :create, "template[/etc/bind/db.#{zone['fqdn']}]", :immediately
  end

  # Template zone file with data from data bag and, if specified, nodes in search
  template "/etc/bind/db.#{zone['fqdn']}" do
    source 'generate_zones.erb'
    variables :zone => zone
    action :nothing
    notifies :run, "execute[reload #{zone['fqdn']}]", :delayed
  end

  # Reload zone, only if named-checkzone returns 0
  execute "reload #{zone['fqdn']}" do
    command "rndc reload #{zone['fqdn']}"
    action :nothing
    only_if "named-checkzone -q #{zone['fqdn']} /etc/bind/db.#{zone['fqdn']}"
  end
end
