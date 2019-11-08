# encoding: utf-8
# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'haproxy-config-checks' do
  impact 1.0
  title 'Tests Haroxy settings for frontend'
  desc '
    This control ensures that:
      * correct ports are used
      * correct frontend is used
      * correct backends are used'
  # stats
  describe port(7331) do
    its('processes') do should eq ['haproxy'] end
    its('addresses') do should eq ['0.0.0.0'] end
    its('protocols') { should eq ['tcp'] }
  end

  # http
  describe port(80) do
    its('processes') do should eq ['haproxy'] end
    its('addresses') do should eq ['0.0.0.0'] end
    its('protocols') { should eq ['tcp'] }
  end

  # https
  describe port(443) do
    its('processes') do should eq ['haproxy'] end
    its('addresses') do should eq ['0.0.0.0'] end
    its('protocols') { should eq ['tcp'] }
  end

  # api_rate_limit_proxy
  describe port(4444) do
    its('processes') do should eq ['haproxy'] end
    its('addresses') { should eq ['127.0.0.1'] }
  end

  # ssh
  describe port(2222) do
    its('processes') do should eq ['haproxy'] end
    its('addresses') do should eq ['0.0.0.0'] end
    its('protocols') { should eq ['tcp'] }
  end

  describe file('/etc/haproxy/cloudflare_ips_v4.lst') do
    it { should be_file }
    its('type') do should eq :file end
    its('owner') do should eq 'root' end
    its('group') do should eq 'root' end
    its('mode') { should cmp '0644' }
  end

  describe file('/etc/haproxy/cloudflare_ips_v6.lst') do
    it { should be_file }
    its('type') do should eq :file end
    its('owner') do should eq 'root' end
    its('group') do should eq 'root' end
    its('mode') { should cmp '0644' }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
  end

  describe file('/etc/haproxy/blacklist-uris.lst') do
    it { should exist }
  end
end
