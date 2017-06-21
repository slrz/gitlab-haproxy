#
# Cookbook Name:: gitlab-haproxy
# Recipe:: pages
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
include_recipe 'chef-vault'
haproxy_secrets = chef_vault_item(node['gitlab-haproxy']['chef_vault'],node['gitlab-haproxy']['chef_vault_item'])['gitlab-haproxy']

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/pages.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['pages_crt']}\n#{haproxy_conf['ssl']['pages_key']}\n"
  notifies :run, "execute[test-haproxy-config]", :delayed
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-pages.cfg.erb'
  mode '0600'
  variables(haproxy_conf.to_hash())
  notifies :run, "execute[test-haproxy-config]", :delayed
end
