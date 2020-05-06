# encoding: utf-8
# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::ci

control 'haproxy-config-checks' do
  impact 1.0
  title 'Additionally tests Haproxy settings for ci fallback'
  desc '
    This control ensures that:
      * there are no fallbkack ACLs or backends
'

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') do should match /acl git_fallback path_reg/ end
    its('content') do should match /acl api_fallback path_reg/ end
    its('content') do should match /use_backend fallback_https_git if git_fallback/ end
    its('content') do should match /use_backend fallback_api if api_fallback/ end
    its('content') do should match /backend fallback_api/ end
    its('content') do should match /backend fallback_https_git/ end
  end
end
