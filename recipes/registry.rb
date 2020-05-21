#
# Cookbook:: gitlab-haproxy
# Recipe:: registry
#
# Copyright:: (C) 2018 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['canary_request_path']['path_list'] = [
  '/v2/charts',
  '/v2/gitlab-com',
  '/v2/gitlab-org/gitlab-ee',
]

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

use_internal = haproxy_secrets['ssl']['internal_key'] && haproxy_secrets['ssl']['internal_crt']
enforce_cf_origin_pull = node['gitlab-haproxy']['registry']['enforce_cloudflare_origin_pull']

file '/etc/haproxy/ssl/registry.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['registry_crt']}\n#{haproxy_secrets['ssl']['registry_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

file '/etc/haproxy/ssl/internal.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['internal_crt']}\n#{haproxy_secrets['ssl']['internal_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { use_internal }
end

# we are only passing in the secrets as variables
template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-registry.cfg.erb'
  mode '0600'
  variables(
    admin_password: haproxy_secrets['admin_password'],
    use_internal: use_internal,
    enforce_cf_origin_pull: enforce_cf_origin_pull,
    backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['registry']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    )
  )
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/canary-request-paths.lst' do
  source 'canary-request-paths.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
