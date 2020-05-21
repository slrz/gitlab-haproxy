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
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  # http
  describe port(80) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
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

  # Test that methods other than a GET or HEAD are rejected by haproxy, with
  # a 403.  Just a selection of methods tested, for practicality.
  %w(POST PUT OPTIONS DELETE FOOBAR).each do |method|
    describe bash("curl -X #{method} -I http://localhost:80/status") do
      # Look at the header output only, and the first line.  Going to be
      # more reliable formatting than the rest of haproxy (e.g. after upgrades)
      its('stdout') { should match %r{^HTTP\/1.0 403 Forbidden} }
    end
  end
end
