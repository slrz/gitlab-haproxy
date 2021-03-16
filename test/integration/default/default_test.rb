# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'general-haproxy-checks' do
  impact 1.0
  title 'General tests for Haroxy service'
  desc '
    This control ensures that:
      * haproxy package is installed
      * haproxy service in enabled and running'

  describe package('haproxy') do
    it { should be_installed }
  end

  describe service('haproxy') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'logrotate-config-valid' do
  impact 1.0
  title 'cron for logrotate is dropped off'

  describe file('/etc/cron.hourly/logrotate') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  describe file('/etc/cron.daily/logrotate') do
    it { should_not exist }
  end

  describe file('/etc/logrotate.d/haproxy') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end
