#
# Cookbook Name:: gitlab-haproxy
# Recipe:: pages
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/pages.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['pages_crt']}\n#{haproxy_secrets['ssl']['pages_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-pages.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'])
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
