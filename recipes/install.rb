#
# Cookbook:: gitlab-haproxy
# Recipe:: install_and_configure
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

raise "need to include #{cookbook_name}::prerequisites before #{cookbook_name}::install" unless node.run_state['HAP_prerequisites_included']

# Install HAProxy 2.8 LTS. Supported until April 2028 - See https://endoflife.date/haproxy
#
# Source, components and key are attributes so an environment can point at the
# internal apt mirror instead of the PPA; see attributes/default.rb for why the
# three have to be overridden together. The key is a vendored cookbook file
# either way, because access to https://keyserver.ubuntu.com is not stable from
# haproxy servers.
apt = node['gitlab-haproxy']['apt']

if apt['keyring']
  # Scope the key to this repository. apt_repository cannot: Cinc 16 has no
  # signed_by property, so it falls back to `apt-key add` and the key lands in
  # /etc/apt/trusted.gpg, where it is trusted for every repository on the node.
  directory '/etc/apt/keyrings' do
    owner 'root'
    group 'root'
    mode '0755'
  end

  cookbook_file "/etc/apt/keyrings/#{apt['keyring']}" do
    source apt['key'].first
    owner 'root'
    group 'root'
    mode '0644'
  end

  apt_update 'haproxy' do
    action :nothing
  end

  file '/etc/apt/sources.list.d/haproxy.list' do
    content "deb [signed-by=/etc/apt/keyrings/#{apt['keyring']}] " \
            "#{apt['uri']} #{node['lsb']['codename']} #{Array(apt['components']).join(' ')}\n"
    owner 'root'
    group 'root'
    mode '0644'
    notifies :update, 'apt_update[haproxy]', :immediately
  end
else
  apt_repository 'haproxy' do
    uri          apt['uri']
    distribution node['lsb']['codename']
    components   apt['components']
    key          apt['key']
  end
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

service 'haproxy' do
  supports [:reload]
end

service 'rsyslog' do
  supports [:restart]
end

package 'haproxy' do
  # We restart rsyslog in order to create the socket HAProxy logs to.
  notifies :restart, 'service[rsyslog]', :delayed
end

# This package installs the debugging symbols required by tools such as perf and gdb.
# These symbols are installed separately and have no performance effect on the haproxy binary itself.
package 'haproxy-dbgsym'

execute 'test-haproxy-config' do
  command 'haproxy -c -f /etc/haproxy/haproxy.cfg'
  notifies :reload, 'service[haproxy]', :delayed
  action :nothing
end

# socat is required to communicate with HAProxy's admin socket
package 'socat'

# Server state persistence - saves backend server states on reload
# This preserves health check status across HAProxy reloads
state_persistence_enabled = node['gitlab-haproxy']['server_state_persistence']['enable']

execute 'systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

# Directory to store the server state file
directory ::File.dirname(node['gitlab-haproxy']['server_state_persistence']['state_file']) do
  owner 'haproxy'
  group 'haproxy'
  mode '0700'
  recursive true
  action state_persistence_enabled ? :create : :delete
end

# Directory for systemd service overrides
directory '/etc/systemd/system/haproxy.service.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action state_persistence_enabled ? :create : :nothing
end

# Systemd override to save server state before reload
file '/etc/systemd/system/haproxy.service.d/state-persistence.conf' do
  action state_persistence_enabled ? :nothing : :delete
  notifies :run, 'execute[systemctl-daemon-reload]', :immediately
end

template '/etc/systemd/system/haproxy.service.d/state-persistence.conf' do
  source 'haproxy-state-override.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action state_persistence_enabled ? :create : :nothing
  notifies :run, 'execute[systemctl-daemon-reload]', :immediately
end

include_recipe 'gitlab-haproxy::agent'
