#
# Cookbook Name:: gitlab-haproxy
# Recipe:: pages
#
# Copyright (C) 2016 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

file '/etc/haproxy/ssl/pages.pem' do
  mode '0600'
  content "#{haproxy_secrets['ssl']['pages_crt']}\n#{haproxy_secrets['ssl']['pages_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-pages.cfg.erb'
  mode '0600'
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
  variables(
    admin_password: haproxy_secrets['admin_password'],
    backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['pages']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    )
  )
end
