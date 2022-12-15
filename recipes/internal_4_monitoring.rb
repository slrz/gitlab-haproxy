# Configure various monitoring settings
#

include_recipe 'gitlab-mtail::haproxy'

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

  # Metrics are now exported directly by HAProxy.
  include_recipe 'gitlab-exporters::haproxy_exporter'
end

node.default['process_exporter']['config'] = {
  process_names: [
    {
      exe: [
        'haproxy',
      ],
    },
  ],
}

include_recipe 'gitlab-exporters::process_exporter'
