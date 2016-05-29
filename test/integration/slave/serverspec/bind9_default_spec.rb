require 'serverspec'

# Required by serverspec
set :backend, :exec

describe "default recipe" do

  it "bind has been installed bind" do
    expect(package("bind9")).to be_installed
  end

  it "bind is listening on port 53" do
    expect(port(53)).to be_listening
  end

  it "bind is running" do
    expect(service("bind9")).to be_running
  end

end
