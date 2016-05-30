require 'serverspec'

# Required by serverspec
set :backend, :exec

describe package('bind9') do
  it { should be_installed }
end

describe port('53') do
  it { should be_listening }
end

describe service('bind9') do
  it { should be_enabled }
  it { should be_running }
end

nameservers = { "ns-foo" => ['192.168.100.10', 'fe80::1:10%eth2'], "ns-bar" => ['192.168.100.20', 'fe80::1:20%eth2'] }

records = {
  "A" => {
    "ttl" => "60",
    "fqdn" => "bar.integrationtesting.local",
    "value" => "127.0.2.1"
  },
  "TXT" => {
    "ttl" =>"100",
    "fqdn" => "boo.integrationtesting.local",
    "value" => "a TXT string"
  }
}

describe "Verify that bind is reachable over IPv4 and IPv6 and responding" do
  nameservers.each do |key, val|
    val.each do |ip|
      describe command("dig @#{ip} NS integrationtesting.local +short") do
        nameservers.each do |x, y|
          its(:stdout) { should match "#{x}.integrationtesting.local"}
        end
      end

      describe "Verify some recoards to see that zone is generated correcrtly" do
        records.each do |x, y|
          describe command("dig @#{ip} #{x} #{y['fqdn']} +short") do
            its(:stdout) { should match "#{y['value']}"}
          end
        end
      end
    end
  end
end
