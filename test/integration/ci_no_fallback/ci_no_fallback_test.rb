# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::ci

control 'haproxy-config-checks' do
  impact 1.0
  title 'Additionally tests Haproxy settings for ci without fallback'
  desc '
    This control ensures that:
      * there are no fallbkack ACLs or backends
'

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') { should_not match /acl git_fallback path_reg/ }
    its('content') { should_not match /acl api_fallback path_reg/ }
    its('content') { should_not match /use_backend fallback_ci_https_git if git_fallback/ }
    its('content') { should_not match /use_backend fallback_ci_api if api_fallback/ }
    its('content') { should_not match /backend fallback_ci_api/ }
    its('content') { should_not match /backend fallback_ci_https_git/ }
  end
end
