#
# Cookbook Name:: gitlab-haproxy
# Recipe:: altssh
#
# Copyright (C) 2017 GitLab Inc.
#
# License: MIT
#
include_recipe 'gitlab-vault'
haproxy_conf = GitLab::Vault.get(node, 'gitlab-haproxy')

include_recipe 'gitlab-haproxy::default'

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-altssh.cfg.erb'
  mode '0600'
  variables(haproxy_conf.to_hash())
  notifies :run, "execute[test-haproxy-config]", :delayed
end
