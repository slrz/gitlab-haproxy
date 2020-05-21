# encoding: utf-8
# frozen_string_literal: true

# InSpec tests for cloudflare configuration

control 'haproxy-config-checks' do
  impact 1.0
  title 'Tests Haroxy settings for cloudflare'
  desc '
    This control ensures that:
      * cloudflare ip whitelists are created
      * cloudflare origin pull certificate is created
      * haproxy configuration does not include `option forwardfor`
      * haproxy configuration includes SSL client verification directives
      * haproxy configuration uses cloudflare ACLs
      * haproxy rate-limiting is not in effect'

  # Attributes expected:
  # node['gitlab-haproxy']['cloudflare']['enable'] = true
  # node['gitlab-haproxy']['frontend']['api_rate_limit']['enforced'] = false
  # node['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull'] = true

  describe file('/etc/haproxy/cloudflare_ips_v4.lst') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  describe file('/etc/haproxy/cloudflare_ips_v6.lst') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  describe file('/etc/haproxy/ssl/cf-origin-pull.pem') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
    its('content') { should match /if from_cf cf_ip_hdr/ }
    its('content') { should match %r{verify required ca-file /etc/haproxy/ssl/cf-origin-pull\.pem} }
    its('content') { should_not match /option forwardfor/ }
    its('content') { should_not match /use_backend 429_slow_down/ }
  end
end
