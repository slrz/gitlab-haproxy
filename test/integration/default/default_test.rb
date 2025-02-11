# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'general-haproxy-checks' do
  impact 1.0
  title 'Basic health checks for HAProxy'
  desc '
    This control ensures that:
      • haproxy package is installed (2.8+)
      • haproxy service in enabled and running
      • essential supplemental files are present
      • the configuration is valid'

  describe package('haproxy') do
    it { should be_installed }
    its('version') { should cmp >= '2.8' }
  end

  describe service('haproxy') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe command('haproxy -c -f /etc/haproxy/haproxy.cfg') do
    its('stdout') { should include 'Configuration file is valid' }
    its('exit_status') { should eq 0 }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
    # Only applicable to new configuration
    its('content') { should include 'log stdout len 4096 format raw daemon' }
    its('content') { should include 'http-errors gitlab-errorcodes' } # error file definition
    its('content') { should include 'errorfiles gitlab-errorcodes' } # default loading of errorfiles
    its('content') { should include 'master-worker no-exit-on-failure' }
    its('content') { should include 'http-request use-service prometheus-exporter' } # native prometheus
    # Default HTTP log format
    its('content') { should include 'log-format %ci:%cp\ %fi:%fp\ %bi:%bp\ %si:%sp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r' }
  end

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

  describe file('/etc/haproxy/ssl/cf-origin-pull.ca') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end

  %w(400 403 429 500 502 503 504 bad_ref).each do |error_page|
    describe file("/etc/haproxy/errors/#{error_page}.http") do
      it { should be_file }
    end
  end

  %w(deny-403-ips deny-403-pages-domains).each do |list|
    describe file("/etc/haproxy/front-end-security/#{list}.lst") do
      it { should be_file }
    end
  end

  describe file('/usr/local/sbin/drain_haproxy.sh') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0750' }
  end

  %w(blocklist-uris canary-request-paths).each do |list|
    describe file("/etc/haproxy/#{list}.lst") do
      it { should be_file }
    end
  end

  describe file('/etc/apt/apt.conf.d/50unattended-upgrades') do
    its('content') { should include 'o=LP-PPA-vbernat-haproxy-2.8' }
  end
end

control 'logrotate-config-valid' do
  impact 1.0
  title 'Logrotate configuration'

  describe package('logrotate') do
    it { should be_installed }
  end

  describe file('/etc/cron.hourly/logrotate') do
    it { should be_file }
    its('type') { should eq :file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  # A bug in logrotate in Ubuntu 22.04 breaks the state-lock functionality. Ensure it becomes disabled.
  # https://bugs.launchpad.net/ubuntu/+source/logrotate/+bug/1977689
  if os.debian? && os[:release].start_with?('22')
    describe file('/etc/cron.hourly/logrotate') do
      its('content') { should match /skip-state-lock/ }
    end
  else
    describe file('/etc/cron.hourly/logrotate') do
      its('content') { should_not match /skip-state-lock/ }
    end
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
