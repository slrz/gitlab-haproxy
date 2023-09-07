#
# Cookbook:: gitlab-haproxy
# Recipe:: internal_4_monitoring
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-mtail::haproxy'

# We only use this third-party exporter with HAProxy 1.8 which doesn't have a built exporter.
# We may still need to use the old configurations on new HAProxy 2.8 nodes.
# TODO: This can only be removed after we successfully migrated to the new configs run by HAProxy 2.8.
# See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
if node['lsb']['codename'] == 'bionic'
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
