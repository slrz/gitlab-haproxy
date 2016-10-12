#
# Cookbook Name:: gitlab-haproxy
# Recipe:: pages
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
include_recipe 'gitlab-vault'
haproxy_conf = GitLab::Vault.get(node, 'gitlab-haproxy')

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/pages.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['pages_crt']}\n#{haproxy_conf['ssl']['pages_key']}\n"
  notifies :reload, 'service[haproxy]'
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-pages.cfg.erb'
  mode '0600'
  variables(haproxy_conf.to_hash())
  notifies :reload, 'service[haproxy]'
end
