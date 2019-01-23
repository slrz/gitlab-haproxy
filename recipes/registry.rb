#
# Cookbook Name:: gitlab-haproxy
# Recipe:: registry
#
# Copyright (C) 2018 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

use_internal = haproxy_secrets['ssl']['internal_key'] && haproxy_secrets['ssl']['internal_crt']

file '/etc/haproxy/ssl/registry.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['registry_crt']}\n#{haproxy_secrets['ssl']['registry_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

file '/etc/haproxy/ssl/internal.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['internal_crt']}\n#{haproxy_secrets['ssl']['internal_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { use_internal }
end

# we are only passing in the secrets as variables
template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-registry.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'], use_internal: use_internal)
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/canary-request-regex-paths.lst' do
  source 'canary-request-regex-paths.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
