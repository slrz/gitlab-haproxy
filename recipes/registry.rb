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

Gitlab::TemplateHelpers.initialize(node)

# To test changes in Non production environment, remove added overrides, and add them to default.rb to rollout to production
# if node['gitlab-haproxy']['is_production']!= true
# Add registry-flavor specific overrides here for non-prod envs
# end

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
