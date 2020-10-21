#
# Cookbook:: gitlab-haproxy
# Recipe:: altssh
#
# Copyright:: (C) 2017 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-altssh.cfg.erb'
  mode '0600'
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
  variables(
    admin_password: haproxy_secrets['admin_password'],
    backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['altssh']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    ),
    backend_canary_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['canary_altssh']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    )
  )
end
