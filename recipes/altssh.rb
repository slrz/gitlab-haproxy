#
# Cookbook Name:: gitlab-haproxy
# Recipe:: altssh
#
# Copyright (C) 2017 GitLab Inc.
#
# License: MIT
#
haproxy_secrets = gitlab_haproxy_secrets['gitlab-haproxy']

include_recipe 'gitlab-haproxy::default'

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy-altssh.cfg.erb'
  mode '0600'
  variables(admin_password: haproxy_secrets['admin_password'])
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
end
