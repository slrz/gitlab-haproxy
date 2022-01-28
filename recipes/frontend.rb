#
# Cookbook:: gitlab-haproxy
# Recipe:: gitlab
#
# Copyright:: (C) 2016 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['close_client_connections'] = true

env = node.chef_environment

if !node['cloud'].nil? && node['cloud']['provider'] == 'gce'
  node.default['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = true
  node.default['gitlab-haproxy']['frontend']['asset_proxy']['host'] = "gitlab-#{env}-assets.storage.googleapis.com"
end

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

use_internal = haproxy_secrets['ssl']['internal_key'] && haproxy_secrets['ssl']['internal_crt']
use_canary = haproxy_secrets['ssl']['canary_key'] && haproxy_secrets['ssl']['canary_crt']
enforce_cf_origin_pull = node['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull']

file '/etc/haproxy/ssl/gitlab.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['gitlab_crt']}\n#{haproxy_secrets['ssl']['gitlab_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

file '/etc/haproxy/ssl/internal.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['internal_crt']}\n#{haproxy_secrets['ssl']['internal_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { use_internal }
end

file '/etc/haproxy/ssl/canary.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['canary_crt']}\n#{haproxy_secrets['ssl']['canary_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { use_canary }
end

file '/etc/haproxy/ssl/ci-gateway.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['ci_gateway_crt']}\n#{haproxy_secrets['ssl']['ci_gateway_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { node['gitlab-haproxy']['ci-gateway']['enabled'] }
end

template '/etc/haproxy/blacklist-uris.lst' do
  source 'blacklist-uris.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

template '/etc/haproxy/canary-request-paths.lst' do
  source 'canary-request-paths.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

# White list for API
template '/etc/haproxy/whitelist-api.lst' do
  source 'whitelist-api.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

# White list for Internal Nodes
template '/etc/haproxy/whitelist-internal.lst' do
  source 'whitelist-internal.lst.erb'
  mode '0600'
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

# IPs that require captcha
git '/etc/haproxy/recaptcha' do
  repository haproxy_secrets['recaptcha']['git_https']
  action :sync
  notifies :run, 'execute[test-haproxy-config]', :delayed
  timeout 15
  ignore_failure true
end

# we are only passing in the secrets as variables
template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-frontend.cfg.erb'
  mode '0600'
  variables(
    admin_password: haproxy_secrets['admin_password'],
    use_internal: use_internal,
    use_canary: use_canary,
    enforce_cf_origin_pull: enforce_cf_origin_pull,
    https_extra_bind_port: node['gitlab-haproxy']['frontend']['https']['extra_bind_port'],
    https_git_acl_format: node['gitlab-haproxy']['frontend']['https_git']['use_verbose_acls'] ? 'verbose' : 'condensed',
    backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['frontend']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    )
  )
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
