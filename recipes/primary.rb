#
# Cookbook:: gitlab-haproxy
# Recipe:: primary
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['flavour'] = 'primary'
include_recipe 'gitlab-haproxy::prerequisites'

git '/etc/haproxy/recaptcha' do
  repository node.run_state['HAP_secrets']['recaptcha']['git_https']
  action :sync
  notifies :run, 'execute[test-haproxy-config]', :delayed
  timeout 15
  ignore_failure true
end

include_recipe 'gitlab-haproxy::install'

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

  node.default['gitlab-haproxy']['close_client_connections'] = true
  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy-frontend.cfg.erb'
    mode '0600'
    variables(
      admin_password: node.run_state['HAP_secrets']['admin_password'],
      use_internal: true,
      use_canary: true,
      use_ci_gateway: true,
      enforce_cf_origin_pull: true,
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
end
