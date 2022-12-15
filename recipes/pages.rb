#
# Cookbook:: gitlab-haproxy
# Recipe:: pages
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['flavour'] = 'pages'
include_recipe 'gitlab-haproxy::prerequisites'

include_recipe 'gitlab-haproxy::install'

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy-pages.cfg.erb'
    mode '0600'
    helpers(Gitlab::TemplateHelpers)
    notifies :run, 'execute[test-haproxy-config]', :delayed
    variables(
      admin_password: node.run_state['HAP_secrets']['admin_password'],
      backend_servers: Gitlab::TemplateHelpers.backend_servers_for_lb_zone(
        node['gitlab-haproxy']['pages']['backend'],
        node.to_h.dig('gce', 'instance', 'zone')
      )
    )
  end
end
