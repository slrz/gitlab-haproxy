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

workers = search(:node, haproxy_conf['worker_chef_query']).map do |n|
  first_ipv4_address = Gitlab.private_ips_for_node(n).first

  next unless first_ipv4_address

  [n.name, first_ipv4_address]
end.compact
workers.sort_by!(&:first) unless workers.empty?

listen_address = Gitlab.private_ips_for_node(node).last

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-pages.cfg.erb'
  mode '0600'
  variables(
    {
      workers: workers,
      listen_address: listen_address
    }.merge(haproxy_conf)
  )
  notifies :reload, 'service[haproxy]'
end
