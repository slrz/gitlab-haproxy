#
# Cookbook Name:: gitlab-haproxy
# Recipe:: gitlab
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#
include_recipe 'gitlab-vault'
haproxy_conf = GitLab::Vault.get(node, 'gitlab-haproxy')

include_recipe 'gitlab-haproxy::default'

file '/etc/haproxy/ssl/gitlab.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['gitlab_crt']}\n#{haproxy_conf['ssl']['gitlab_key']}\n"
  notifies :run, "execute[test-haproxy-config]", :delayed
end

file '/etc/haproxy/ssl/ci.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['ci_crt']}\n#{haproxy_conf['ssl']['ci_key']}\n"
  notifies :reload, 'service[haproxy]'
end

file '/etc/haproxy/ssl/registry.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['registry_crt']}\n#{haproxy_conf['ssl']['registry_key']}\n"
  notifies :run, "execute[test-haproxy-config]", :delayed
end

template '/etc/haproxy/haproxy.cfg' do
  mode '0600'
  variables(haproxy_conf.to_hash())
  notifies :run, "execute[test-haproxy-config]", :delayed
end
