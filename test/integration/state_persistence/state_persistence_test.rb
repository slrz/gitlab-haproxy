# frozen_string_literal: true

# InSpec tests for server state persistence feature

control 'server-state-persistence-enabled' do
  impact 1.0
  title 'Server state persistence is properly configured when enabled'
  desc '
    This control ensures that server state persistence is properly configured:
      • State directory exists with correct permissions
      • HAProxy config includes server-state-file directive
      • HAProxy config includes load-server-state-from-file directive
      • Systemd override is in place for state save on reload/stop
      • Server lines include init-addr directive
      • socat package is installed'

  describe directory('/etc/haproxy/state') do
    it { should exist }
    its('owner') { should eq 'haproxy' }
    its('group') { should eq 'haproxy' }
    its('mode') { should cmp '0700' }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') { should include 'server-state-file /etc/haproxy/state/global' }
    its('content') { should include 'load-server-state-from-file global' }
    its('content') { should match /init-addr \d+\.\d+\.\d+\.\d+/ }
  end

  describe file('/etc/systemd/system/haproxy.service.d/state-persistence.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'ExecReload=' }
    its('content') { should include 'show servers state' }
    its('content') { should include 'ExecStop=' }
    its('content') { should include 'KillSignal=SIGUSR1' }
  end

  describe package('socat') do
    it { should be_installed }
  end
end
