#
# Cookbook:: gitlab-haproxy
# Recipe:: temporary_hacks
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#
# This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

# Remove me after moving around the attributes in roles:
node.default['gitlab-haproxy']['frontend']['blocklist']['uri'] = node['gitlab-haproxy']['frontend']['blacklist']['uri']
node.default['gitlab-haproxy']['frontend']['allowlist']['internal'] = node['gitlab-haproxy']['frontend']['whitelist']['internal']
node.default['gitlab-haproxy']['frontend']['allowlist']['api'] = node['gitlab-haproxy']['frontend']['whitelist']['api']
node.default['gitlab-haproxy']['frontend']['https']['rate_limit_allowlist'] = node['gitlab-haproxy']['frontend']['https']['rate_limit_whitelist']
node.default['gitlab-haproxy']['config']['default']['global']['hard-stop-after'] = node['gitlab-haproxy']['global']['hard-stop']['timeout']

# Pages does not have their own check config, but the old HAP config just used the one from the main:
# Fix this in roles!
node.default['gitlab-haproxy']['pages']['default_check_opts'] = node['gitlab-haproxy']['frontend']['default_check_opts']

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

  # Considering we are running a dedicated PPA with just a 2.6 LTS release, and HAProxy 2.6 properly does hitless restarts
  # Thanks to process management implemented in HAP 2.0, it's safe to update patch versions. Also required for security fixes, which in the past we did not install...
  node.default['apt']['unattended_upgrades']['package_blacklist'] << 'haproxy'

  # In case we wanted to support more cipher suites without copying the existing default one.
  unless (extra_ciphers = node['gitlab-haproxy']['global']['extra-default-bind-ciphers']).empty?
    node.default['gitlab-haproxy']['global']['ssl-default-bind-ciphers'].prepend(extra_ciphers + ':')
  end

  # rubocop:disable Chef/Modernize # Chef 15 adds helpers cookstyle wants to use here
  if ENV['TEST_KITCHEN']
    # Hacky way to prevent `unable to find local peer` messages in kitchen.
    # Only needed because of extensive regression tests. Previously kitchen just didn't have peers.
    node.default['gitlab-haproxy']['frontend']['peers']['servers'][node['hostname']] = [node['gitlab-haproxy']['api_address'], 32768]
    node.default['gitlab-haproxy']['pages']['peers']['servers'][node['hostname']] = [node['gitlab-haproxy']['api_address'], 32768]
    node.default['gitlab-haproxy']['registry']['peers']['servers'][node['hostname']] = [node['gitlab-haproxy']['api_address'], 32768]
  end

  %w(/etc/haproxy/ssl /etc/systemd/system/haproxy.service.d /etc/haproxy/state).each do |dir|
    directory dir do
      mode '0700'
      recursive true
    end
  end

  # https://gitlab.com/gitlab-org/gitlab/-/issues/7554
  template '/etc/haproxy/blacklist-uris.lst' do
    source 'lists/blocklist-uris.lst.erb'
    mode '0600'
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  # https://gitlab.com/gitlab-org/gitlab/-/issues/7554
  # White list for API
  template '/etc/haproxy/whitelist-api.lst' do
    source 'lists/allowlist-api.lst.erb'
    mode '0600'
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  # allow list for Internal Nodes
  template '/etc/haproxy/whitelist-internal.lst' do
    source 'lists/allowlist-internal.lst.erb'
    mode '0600'
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  # HAProxy 2.6 drains properly, so the hacks around draining are no longer necessary on 2.6+
  # The upstream systemd unit also makes proper use of the new process management of HAProxy
  template '/etc/systemd/system/haproxy.service.d/override.conf' do
    source 'override.conf.erb'
    mode '0644'
    notifies :run, 'execute[systemd reload]', :delayed
  end

  cookbook_file '/etc/haproxy/ssl/cf-origin-pull.pem' do
    source 'origin-pull-ca.pem'
    sensitive true
    owner 'root'
    group 'root'
    mode '0600'
    action :create
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  execute 'systemd reload' do
    command 'systemctl daemon-reload'
    action :nothing
  end
end
