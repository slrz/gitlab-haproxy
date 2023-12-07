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

# This block generates the old configs.
# We may still need to use the old configurations on new HAProxy 2.8 nodes.
# TODO: This can only be removed after we successfully migrated to the new configs run by HAProxy 2.8
# See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
if node['gitlab-haproxy']['use_old_config']
  node.default['gitlab-haproxy']['close_client_connections'] = true

  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy-frontend.cfg.erb'
    mode '0600'
    variables(
      admin_password: node.run_state['HAP_secrets']['admin_password'],
      use_internal: true,
      use_canary: node['gitlab-haproxy']['use_canary'],
      use_ci_gateway: node['gitlab-haproxy']['ci-gateway']['enabled'],
      enforce_cf_origin_pull: node['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull'],
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
else # !node['gitlab-haproxy']['use_old_config']
  # CI gateway frontends and backends have to be disabled in pre environment
  unless node['gitlab-haproxy']['ci-gateway']['enabled']
    node.default['gitlab-haproxy']['enabled_frontends']['main'].delete('https_git_ci_gateway')
    node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_catch_all')
    node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_git_repo_redirection')
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
end
