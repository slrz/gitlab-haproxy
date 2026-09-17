# frozen_string_literal: true

# InSpec tests for the haproxy apt sources and pins

control 'haproxy-apt-sources' do
  impact 1.0
  title 'Two haproxy apt sources with the second one pinned below the first'
  desc '
    The main suite lists the 2.8 and 3.0 PPAs with a pin on the 3.0 origin.
    apt must see both versions and still pick 2.8 as the candidate.'

  describe file('/etc/apt/sources.list.d/haproxy.list') do
    its('content') { should include 'ppa.launchpadcontent.net/vbernat/haproxy-2.8/ubuntu' }
  end

  describe file('/etc/apt/sources.list.d/haproxy-1.list') do
    its('content') { should include 'ppa.launchpadcontent.net/vbernat/haproxy-3.0/ubuntu' }
  end

  describe file('/etc/apt/preferences.d/haproxy') do
    its('content') { should include "Pin: release o=LP-PPA-vbernat-haproxy-3.0\nPin-Priority: 400" }
  end

  describe command('apt-cache policy haproxy') do
    its('stdout') { should match(/Candidate: 2\.8\./) }
    its('stdout') { should match(/^\s+400 https:\/\/ppa\.launchpadcontent\.net\/vbernat\/haproxy-3\.0/) }
  end

  describe command('apt-cache madison haproxy') do
    its('stdout') { should match(/haproxy \| 3\.0\./) }
  end

  describe package('haproxy') do
    its('version') { should match(/^2\.8\./) }
  end
end
