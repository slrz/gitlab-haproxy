#
# Cookbook:: gitlab-haproxy
# Recipe:: internal_4_monitoring
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-mtail::haproxy'

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
