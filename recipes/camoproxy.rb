#
# Cookbook Name:: gitlab-haproxy
# Recipe:: camoproxy
#
# Copyright (C) 2019 GitLab Inc.
#
# License: MIT
#

include_recipe 'gitlab-haproxy::default'

haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-camoproxy.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'])
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
