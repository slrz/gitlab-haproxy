#
# Cookbook:: gitlab-haproxy
# Recipe:: ci
#
# Copyright:: (C) 2016 GitLab Inc.
#
# License: MIT
#

# Let's use HAProxy 2.1
node.default['gitlab-haproxy']['major-version'] = 'haproxy-2.1'

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

file '/etc/haproxy/ssl/ci.pem' do
  sensitive true
  mode '0600'
  content "#{haproxy_secrets['ssl']['ci_crt']}\n#{haproxy_secrets['ssl']['ci_key']}\n"
  notifies :run, 'execute[test-haproxy-config]', :delayed
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

# we are only passing in the secrets as variables
template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-ci.cfg.erb'
  mode '0600'
  variables(
    admin_password: haproxy_secrets['admin_password'],
    backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
      node['gitlab-haproxy']['ci']['backend'],
      node.to_h.dig('gce', 'instance', 'zone')
    )
  )
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
