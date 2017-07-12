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
  #stats
  describe port(7331) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['127.0.0.1'] }
    its('protocols') { should eq ['tcp'] }
  end

  #https
  describe port(443) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  #api_rate_limit_proxy
  describe port(7001) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['127.0.0.1'] }
    its('protocols') { should eq ['tcp'] }
  end

end

