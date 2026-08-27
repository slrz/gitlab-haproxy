# frozen_string_literal: true

# InSpec tests for the gitlab-haproxy-agent install

control 'gitlab-haproxy-agent' do
  impact 1.0
  title 'gitlab-haproxy-agent is installed and set up when enabled'
  desc '
    The kitchen VM has no consul, so the agent cannot reach a running state
    (it exits until the first consul sync succeeds and relies on systemd
    restarting it). This control covers everything up to that point:
      • the versioned release binary is installed and actually executes
      • the systemd unit exists, carries the configured flags, and is enabled'

  describe command('/opt/gitlab-haproxy-agent/*/gitlab-haproxy-agent --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/\d+\.\d+\.\d+/) }
  end

  describe file('/etc/systemd/system/gitlab-haproxy-agent.service') do
    it { should exist }
    its('content') { should match %r{ExecStart=/opt/gitlab-haproxy-agent/[\d.]+/gitlab-haproxy-agent} }
    its('content') { should include '--listen-addr 127.0.0.1:9777' }
    its('content') { should include '--monitoring-addr :9778' }
    its('content') { should include 'Restart=always' }
  end

  describe service('gitlab-haproxy-agent') do
    it { should be_enabled }
  end
end
