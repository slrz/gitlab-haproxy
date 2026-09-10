# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'haproxy-registry-config-checks' do
  impact 1.0
  title 'Basic checks for HAProxy (registry flavor)'
  desc '
    This control ensures that:
      • correct ports are used
      • correct frontend is used
      • correct backends are used'

  # stats
  describe port(7331) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  # TCP admin socket off in this suite (tcp_admin_socket: false)
  describe port(23646) do
    it { should_not be_listening }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') { should_not include ':23646' }
    its('content') { should include 'stats socket /run/haproxy/admin.sock' }
  end

  # http
  describe port(80) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  # https
  describe port(443) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
  end
end
