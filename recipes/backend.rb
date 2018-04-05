#
# Cookbook Name:: gitlab-haproxy
# Recipe:: gitlab
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/gitlab.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['gitlab_crt']}\n#{haproxy_secrets['ssl']['gitlab_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-backend.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'])
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
