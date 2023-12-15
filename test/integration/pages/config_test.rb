# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::default

control 'haproxy-pages-config-checks' do
  impact 1.0
  title 'Basic checks for HAProxy (pages flavor)'
  desc '
    This control ensures that:
      • correct ports are bound'

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

  # https
  describe port(443) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end
end
