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

  describe file('/opt/gitlab-haproxy-agent/bin/gitlab-haproxy-agent') do
    it { should be_symlink }
  end

  describe command('/opt/gitlab-haproxy-agent/bin/gitlab-haproxy-agent --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/\d+\.\d+\.\d+/) }
  end

  describe file('/etc/systemd/system/gitlab-haproxy-agent.service') do
    it { should exist }
    its('content') { should include 'ExecStart=/opt/gitlab-haproxy-agent/bin/gitlab-haproxy-agent' }
    its('content') { should include '"--listen-addr" "127.0.0.1:9777"' }
    its('content') { should include '"--monitoring-addr" ":9778"' }
    its('content') { should include '"--consul-addr" "127.0.0.1:8500"' }
    its('content') { should include 'Restart=always' }
  end

  describe service('gitlab-haproxy-agent') do
    it { should be_enabled }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') { should match %r{server gke-cny-web .* agent-check agent-addr 127\.0\.0\.1 agent-port 9777 agent-send "canary_web/gke-cny-web canary\\n" agent-inter 2s} }
    its('content') { should match %r{agent-send "web/gke-cny-web canary\\n"} }
  end

  describe command(%q(grep -E 'agent-send "[^"]* canary\\n"' /etc/haproxy/haproxy.cfg | grep -v -- '-cny-')) do
    its('stdout') { should eq '' }
  end

  # asset_proxy and packhorse write their single external server inline; every
  # other server line goes through the boilerplate and must get agent-check.
  describe command(%q(awk '/^[a-z]/{s=$1} s=="backend" && /^[[:space:]]+server /' /etc/haproxy/haproxy.cfg | grep -v agent-check | grep -vE '^[[:space:]]+server (asset-bucket|packhorse_lb) ')) do
    its('stdout') { should eq '' }
  end
end
