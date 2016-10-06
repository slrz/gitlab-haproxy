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
  notifies :reload, 'service[haproxy]'
end

file '/etc/haproxy/ssl/ci.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['ci_crt']}\n#{haproxy_conf['ssl']['ci_key']}\n"
  notifies :reload, 'service[haproxy]'
end

file '/etc/haproxy/ssl/registry.pem' do
  mode '0600'
  content "#{haproxy_conf['ssl']['registry_crt']}\n#{haproxy_conf['ssl']['registry_key']}\n"
  notifies :reload, 'service[haproxy]'
end

workers = search(:node, haproxy_conf['worker_chef_query']).map do |n|
  first_ipv4_address = Gitlab.private_ips_for_node(n).first

  next unless first_ipv4_address

  [n.name, first_ipv4_address]
end.compact
workers.sort_by!(&:first) unless workers.empty?

listen_address = Gitlab.private_ips_for_node(node).last

cookbook_file '/etc/haproxy/slow-hand.lua' do
    source 'slow-hand.lua'
    owner 'root'
    group 'root'
    mode '0600'
    action :create
end

template '/etc/haproxy/haproxy.cfg' do
  mode '0600'
  variables(
    {
      workers: workers,
      listen_address: listen_address
    }.merge(haproxy_conf)
  )
  notifies :reload, 'service[haproxy]'
end
