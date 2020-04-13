# Configure various monitoring settings
#

include_recipe 'gitlab-mtail::haproxy'
include_recipe 'gitlab-exporters::haproxy_exporter'

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
