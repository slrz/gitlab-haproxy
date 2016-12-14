#
# Cookbook Name:: gitlab-haproxy
# Recipe:: default
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
case node['platform']
when 'ubuntu'
  case node['platform_version']
  when /^14\.04/
    # We want HAProxy 1.5 with better SSL support, which is not in Ubuntu 14.04
    template '/etc/apt/sources.list.d/haproxy.list' do
      notifies :run, 'execute[apt-get update]', :immediately
    end

    execute 'apt-get update' do
      action :nothing
    end
  end
end

package 'haproxy'

directory '/etc/haproxy/ssl' do
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

service 'haproxy' do
  supports [:reload]
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
