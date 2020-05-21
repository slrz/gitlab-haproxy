#
# Cookbook:: gitlab-haproxy
# Recipe:: camoproxy
#
# Copyright:: (C) 2019 GitLab Inc.
#
# License: MIT
#

node.default['gitlab-haproxy']['timeout_server'] = '90s'

include_recipe 'gitlab-haproxy::default'

# For the deny list builder
package 'ruby'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-camoproxy.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'])
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

cookbook_file '/usr/local/bin/build-camoproxy-deny-list.rb' do
  source 'build-camoproxy-deny-list.rb'
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'update-camoproxy-deny-list' do
  command '/usr/local/bin/build-camoproxy-deny-list.rb'
  action :nothing
  # Explicitly run immediately before any test/reload happens, to ensure the required file is generated
  # Could listen/subscribe to the git update, but that doesn't catch all scenarios/run orders.
  subscribes :run, 'execute[test-haproxy-config]', :before
end
