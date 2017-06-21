#
# Cookbook Name:: gitlab-haproxy
# Recipe:: gitlab
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
include_recipe 'chef-vault'
haproxy_secrets = chef_vault_item(node['gitlab-haproxy']['chef_vault'],node['gitlab-haproxy']['chef_vault_item'])['gitlab-haproxy']

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/gitlab.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['gitlab_crt']}\n#{haproxy_secrets['ssl']['gitlab_key']}\n"
  notifies :run, "execute[test-haproxy-config]", :delayed
end

file '/etc/haproxy/ssl/ci.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['ci_crt']}\n#{haproxy_secrets['ssl']['ci_key']}\n"
  notifies :reload, 'service[haproxy]'
end

file '/etc/haproxy/ssl/registry.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['registry_crt']}\n#{haproxy_secrets['ssl']['registry_key']}\n"
  notifies :run, "execute[test-haproxy-config]", :delayed
end

# we are only passing in the secrets as variables
template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-frontend.cfg.erb'
  mode '0600'
  variables(haproxy_secrets.to_hash())
  notifies :run, "execute[test-haproxy-config]", :delayed
end
