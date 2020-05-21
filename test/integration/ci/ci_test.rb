# encoding: utf-8
# frozen_string_literal: true

# InSpec tests for recipe gitlab-haproxy::ci

control 'haproxy-config-checks' do
  impact 1.0
  title 'Tests Haproxy settings for ci'
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

  describe package('haproxy') do
    it { should be_installed }
    its('version') { should cmp >= '2.1.0' }
  end

  # https
  describe port(443) do
    its('processes') { should eq ['haproxy'] }
    its('addresses') { should eq ['0.0.0.0'] }
    its('protocols') { should eq ['tcp'] }
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    its('mode') { should cmp '0600' }
    its('content') { should match /acl is_ci_api path_reg/ }
    its('content') { should match /acl is_ci_api_get path_reg/ }
    its('content') { should match /acl is_https_git path_reg/ }
    its('content') { should match /acl is_canary_path path_beg/ }
    its('content') { should match /acl blacklist-uri path_beg/ }
    its('content') { should match /use_backend ci_api if is_ci_api is_api_method/ }
    its('content') { should match /use_backend ci_api if is_ci_api_get is_api_get_method/ }
    its('content') { should match /use_backend ci_https_git if is_https_git is_git_method/ }
    its('content') { should match /default_backend return_403/ }
    its('content') { should match /server canary.api01.gitlab.com 127.0.0.1:443 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
    its('content') { should match /server canary.api01.gitlab.com 127.0.0.1:443 weight 0 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
    its('content') { should match /server api01.gitlab.com 127.0.0.1:443 weight 100 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
    its('content') { should match /server canary.api01.gitlab.com 127.0.0.1:443 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
    its('content') { should match /server canary.api01.gitlab.com 127.0.0.1:443 weight 0 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
    its('content') { should match /server git01.gitlab.com 127.0.0.1:443 weight 100 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 port 5001 ssl verify none/ }
  end

  describe file('/etc/haproxy/blacklist-uris.lst') do
    it do should exist end
    its('content') { should match /Testing/ }
  end

  describe file('/etc/haproxy/canary-request-paths.lst') do
    it do should exist end
  end
end
