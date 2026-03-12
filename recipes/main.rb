#
# Cookbook:: gitlab-haproxy
# Recipe:: main
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['flavor'] = 'main'

include_recipe 'gitlab-haproxy::prerequisites'

git '/etc/haproxy/recaptcha' do
  repository node.run_state['HAP_secrets']['recaptcha']['git_https']
  action :sync
  notifies :run, 'execute[test-haproxy-config]', :delayed
  timeout 15
  ignore_failure true
end

include_recipe 'gitlab-haproxy::install'

# CI gateway frontends and backends have to be disabled in pre environment
unless node['gitlab-haproxy']['ci-gateway']['enabled']
  node.default['gitlab-haproxy']['enabled_frontends']['main'].delete('https_git_ci_gateway')
  node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_catch_all')
  node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_git_repo_redirection')
end

# To test changes in Non production environment, remove added overrides, and add them to default.rb to rollout to production
unless node['gitlab-haproxy']['is_production']
  node.default['gitlab-haproxy']['config']['main']['backend']['api']['retry-on'] = 'conn-failure response-timeout # To match old nginx configuration'
  node.default['gitlab-haproxy']['config']['main']['backend']['api']['option'] = 'redispatch # Allows HAproxy to retry another server in case of retry , this behaviour was enabled by default in NGINX'
  node.default['gitlab-haproxy']['config']['main']['backend']['api']['timeout connect'] = '300s # Copied from old nginx configuration , proxy_connect_timeout 300s'
  node.default['gitlab-haproxy']['config']['main']['backend']['api']['timeout client'] = '60s # Copied from old nginx configuration , proxy_send_timeout 60s'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_api']['timeout connect'] = '300s # Copied from old nginx configuration , proxy_connect_timeout 300s'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_api']['timeout client'] = '60s # Copied from old nginx configuration , proxy_send_timeout 60s'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_api']['retry-on'] = 'conn-failure response-timeout # To match old nginx configuration'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_api']['option'] = 'redispatch # Allows HAproxy to retry another server in case of retry , this behaviour was enabled by default in NGINX'
  node.default['gitlab-haproxy']['config']['main']['backend']['main_api']['timeout connect'] = '300s # Copied from old nginx configuration , proxy_connect_timeout 300s'
  node.default['gitlab-haproxy']['config']['main']['backend']['main_api']['timeout client'] = '60s # Copied from old nginx configuration , proxy_send_timeout 60s'
  node.default['gitlab-haproxy']['config']['main']['backend']['main_api']['retry-on'] = 'conn-failure response-timeout # To match old nginx configuration'
  node.default['gitlab-haproxy']['config']['main']['backend']['main_api']['option'] = 'redispatch # Allows HAproxy to retry another server in case of retry , this behaviour was enabled by default in NGINX'
  node.default['gitlab-haproxy']['enabled_backends']['main'].push('kas_grpc', 'kas_websocket', 'canary_kas_grpc', 'canary_kas_websocket')
  node.default['gitlab-haproxy']['config']['main']['backend']['kas_grpc']['timeout server'] = '1h # KAS specific tuning for SPDY'
  node.default['gitlab-haproxy']['config']['main']['backend']['kas_grpc']['timeout tunnel'] = '2h'
  node.default['gitlab-haproxy']['config']['main']['backend']['kas_websocket']['timeout server'] = '1h # KAS specific tuning for SPDY'
  node.default['gitlab-haproxy']['config']['main']['backend']['kas_websocket']['timeout tunnel'] = '2h'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_kas_grpc']['timeout server'] = '1h # KAS specific tuning for SPDY'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_kas_grpc']['timeout tunnel'] = '2h'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_kas_websocket']['timeout server'] = '1h # KAS specific tuning for SPDY'
  node.default['gitlab-haproxy']['config']['main']['backend']['canary_kas_websocket']['timeout tunnel'] = '2h'
end

Gitlab::TemplateHelpers.initialize(node)

# Because chef code is run at compile time, we need to run this in a runtime block and save it to the run_state.
ruby_block 'get available certificates' do
  block do
    node.run_state['HAP_available_certificates'] = Dir.glob('/etc/haproxy/ssl/*.pem')
  end
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-base.cfg.erb'
  mode '0600'
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
