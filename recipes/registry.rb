#
# Cookbook:: gitlab-haproxy
# Recipe:: registry
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT

node.default['gitlab-haproxy']['flavour'] = 'registry'
include_recipe 'gitlab-haproxy::prerequisites'

include_recipe 'gitlab-haproxy::install'

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

  # we are only passing in the secrets as variables
  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy-registry.cfg.erb'
    mode '0600'
    variables(
      admin_password: node.run_state['HAP_secrets']['admin_password'],
      use_internal: true,
      enforce_cf_origin_pull: node['gitlab-haproxy']['registry']['enforce_cloudflare_origin_pull'],
      backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
        node['gitlab-haproxy']['registry']['backend'],
        node.to_h.dig('gce', 'instance', 'zone')
      )
    )
    helpers(Gitlab::TemplateHelpers)
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end
end
