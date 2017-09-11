#
# Cookbook Name:: gitlab-haproxy
# Recipe:: default
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
package 'haproxy'
package 'logrotate'

eth = node['network']['interfaces'].select { |_k, v| v['encapsulation'] == 'Ethernet' }.values.first
node.default['gitlab-haproxy']['bind_address'] = eth['addresses'].detect { |_k, v| v[:family] == 'inet' }.first

directory '/etc/haproxy/ssl' do
  mode '0700'
  recursive true
end

directory '/etc/haproxy/errors' do
  mode '0700'
  recursive true
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

cookbook_file '/etc/haproxy/errors/bad_ref.http' do
  source 'haproxy-errors-bad-ref.http'
end

service 'haproxy' do
  supports [:reload]
end

execute 'test-haproxy-config' do
  command 'haproxy -c -L fe01 -f /etc/haproxy/haproxy.cfg'
  # This doens't work for peer statements as the test-box will never
  # have the valid name of the server in the config, and augmenting
  # test structures for a service reload is a PITA.
  # TODO: Figure some better way to test a reload
  # notifies :reload, 'service[haproxy]', :delayed
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
