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

  describe file('/etc/haproxy/haproxy.cfg') do
    its('md5sum') do should eq '3ec6e3961c6d9209b63c1c4605213dc7' end
    its('mode') { should cmp '0600' }
  end
end
