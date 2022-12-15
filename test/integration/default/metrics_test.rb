# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'haproxy-metrics-checks' do
  impact 1.0
  title 'Basic metric checks for HAProxy'
  desc '
    This control ensures that:
      * haproxy-exporter is running (on 18.04)
      * haproxy binds on port 9091 (on 20.04+)
      * it exposes metrics'

  describe processes('haproxy_exporter') do
    if command('lsb_release -rs').stdout =~ /18\.04/
      it { should be_running }
    else
      skip 'haproxy_exporter not expected'
    end
  end

  # haproxy-exporter
  describe port(9101) do
    if command('lsb_release -rs').stdout =~ /18\.04/
      its('processes') { should match [/haproxy_export/] } # This is cut short sometimes
    else
      its('processes') { should match [/haproxy/] }
    end
    its('protocols') { should eq ['tcp'] }
  end

  describe http('http://localhost:9101/metrics') do
    its('status') { should cmp 200 }
    its('body') { should include 'haproxy_frontend_connections_total' }
  end
end
