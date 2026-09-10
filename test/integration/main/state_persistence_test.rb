# frozen_string_literal: true

# InSpec tests: server state persistence was removed in 7.38.0

control 'server-state-persistence-removed' do
  impact 1.0
  title 'Server state persistence is gone'
  desc '
    This control ensures nothing of server state persistence remains:
      • State directory does not exist
      • HAProxy config does not include server-state-file directive
      • HAProxy config does not include load-server-state-from-file directive
      • Systemd override does not exist
      • Server lines do not include init-addr directive'

  describe directory('/etc/haproxy/state') do
    it { should_not exist }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') { should_not include 'server-state-file' }
    its('content') { should_not include 'load-server-state-from-file' }
    its('content') { should_not match /init-addr \d+\.\d+\.\d+\.\d+/ }
  end

  describe file('/etc/systemd/system/haproxy.service.d/state-persistence.conf') do
    it { should_not exist }
  end
end

control 'socat-installed' do
  impact 0.5
  title 'socat package is installed unconditionally'
  desc 'socat is installed unconditionally for HAProxy admin socket access'

  describe package('socat') do
    it { should be_installed }
  end
end
