# encoding: utf-8
# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'haproxy-config-checks' do
  impact 1.0
  title 'Tests Haproxy settings for camoproxy'
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

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
  end

  describe file('/usr/local/bin/build-camoproxy-deny-list.rb') do
    its('mode') { should cmp '0755' }
  end

  # This file is created by an exec that hooks before the haproxy reload
  # and it's super important that it is actually created
  describe file('/etc/haproxy/front-end-security/deny-403-urls-camoproxy.lst') do
    its('mode') { should cmp '0644' }
  end
end
