#
# Cookbook Name:: gitlab-haproxy
# Recipe:: default
#
# Copyright (C) 2019 GitLab Inc.
#
# License: MIT
#
include_recipe 'apt'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

service 'rsyslog' do
  supports [:restart]
end

package 'haproxy' do
  # We restart rsyslog in order to create the socket HAProxy logs to
  notifies :restart, 'service[rsyslog]', :delayed
end

package 'logrotate'
package 'socat'

eth = node['network']['interfaces'].select { |_k, v| v['encapsulation'] == 'Ethernet' }.values.first
node.default['gitlab-haproxy']['api_address'] = eth['addresses'].detect { |_k, v| v[:family] == 'inet' }.first

%w(/etc/haproxy/ssl /etc/haproxy/errors /etc/haproxy/state /etc/systemd/system/haproxy.service.d).each do |dir|
  directory dir do
    mode '0700'
    recursive true
  end
end

cookbook_file '/etc/haproxy/errors/400.http' do
  source 'haproxy-errors-400.http'
end
cookbook_file '/etc/haproxy/errors/429.http' do
  source 'haproxy-errors-429.http'
end
cookbook_file '/etc/haproxy/errors/500.http' do
  source 'haproxy-errors-500.http'
end
cookbook_file '/etc/haproxy/errors/502.http' do
  source 'haproxy-errors-502.http'
end
cookbook_file '/etc/haproxy/errors/bad_ref.http' do
  source 'haproxy-errors-bad-ref.http'
end

template '/etc/haproxy/errors/503.http' do
  source 'haproxy-errors-503.http.erb'
end
cookbook_file '/etc/haproxy/errors/504.http' do
  source 'haproxy-errors-504.http'
end

# blacklist for incoming requests
git '/etc/haproxy/front-end-security' do
  repository haproxy_secrets['front-end-security']['git_https']
  revision 'master'
  action :sync
  notifies :run, 'execute[test-haproxy-config]', :delayed
  timeout 15
  ignore_failure true
end

service 'haproxy' do
  supports [:reload]
end

execute 'test-haproxy-config' do
  # command 'ifconfig eth0:1 $(grep "peer fe01" /etc/haproxy/haproxy.cfg  | sed "s/.* //;s/:.*//") up; haproxy -L fe01 -f /etc/haproxy/haproxy.cfg'
  command 'haproxy -c -f /etc/haproxy/haproxy.cfg'
  # This doens't work for peer statements as the test-box will never
  # have the valid name of the server in the config, and augmenting
  # test structures for a service reload is a PITA.
  # TODO: Figure some better way to test a reload
  notifies :reload, 'service[haproxy]', :delayed
  action :nothing
end

cookbook_file '/etc/cron.hourly/logrotate' do
  source 'logrotate-cron'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/etc/logrotate.d/haproxy' do
  source 'logrotate-haproxy'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/systemd/system/haproxy.service.d/override.conf' do
  mode '0644'
  notifies :run, 'execute[systemd reload]', :delayed
  action node['gitlab-haproxy']['systemd_service_overrides']['enable'] ? :create : :delete
end

execute 'systemd reload' do
  command 'systemctl daemon-reload'
  action :nothing
end
