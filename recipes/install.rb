#
# Cookbook:: gitlab-haproxy
# Recipe:: install_and_configure
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

raise "need to include #{cookbook_name}::prerequisites before #{cookbook_name}::install" unless node.run_state['HAP_prerequisites_included']

# We may still need to use the old configurations on new HAProxy 2.6 nodes.
# TODO: This can only be removed after we successfully migrated to the new configs run by HAProxy 2.6.
# See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
if node['lsb']['codename'] == 'bionic'
  apt_repository 'haproxy' do
    uri "ppa:vbernat/#{node['gitlab-haproxy']['major-version']}"
  end

  package 'hatop' # This is an ancient version (0.7.7) from 2010
else
  # Install HAProxy 2.6 LTS.
  # Supported until April 2027
  apt_repository 'haproxy' do
    uri 'ppa:vbernat/haproxy-2.6'
  end

  # Required as hatop only invokes `python` and ubuntu ships with `python3`.
  # This package creates a symlink.
  package 'python-is-python3'

  # jhunt maintains hatop now. Just a python script. Updated this year.
  remote_file '/usr/local/bin/hatop' do
    source 'https://github.com/jhunt/hatop/releases/download/v0.8.2/hatop'
    mode '0755'
    atomic_update true
    retries 3
    action :create

    use_conditional_get true
    use_etag true
  end
end

service 'haproxy' do
  supports [:reload]
end

service 'rsyslog' do
  supports [:restart]
end

package 'haproxy' do
  # We restart rsyslog in order to create the socket HAProxy logs to
  # TODO: This may not be necessary on Ubuntu 20.04, as we log through systemd to rsyslog
  notifies :restart, 'service[rsyslog]', :delayed
end

execute 'test-haproxy-config' do
  command 'haproxy -c -f /etc/haproxy/haproxy.cfg'
  notifies :reload, 'service[haproxy]', :delayed
  action :nothing
end
