#
# Cookbook:: gitlab-haproxy
# Recipe:: registry
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['flavor'] = 'registry'
include_recipe 'gitlab-haproxy::prerequisites'

include_recipe 'gitlab-haproxy::install'

# This block generates the old configs.
# We may still need to use the old configurations on new HAProxy 2.8 nodes.
# TODO: This can only be removed after we successfully migrated to the new configs run by HAProxy 2.8.
# See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
if node['lsb']['codename'] == 'bionic' || node['gitlab-haproxy']['use_old_config']
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
else # node['lsb']['codename'] != 'bionic' && !node['gitlab-haproxy']['use_old_config']
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
