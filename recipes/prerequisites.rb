#
# Cookbook:: gitlab-haproxy
# Recipe:: prerequisites
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

apt_update do
  action :update
end

# On Ubuntu 20.04, we always install the latest patch version of HAProxy 2.6
if node['lsb']['codename'] != 'bionic'
  node.default['apt']['unattended_upgrades']['origins_patterns'] += [
    'o=LP-PPA-vbernat-haproxy-2.8',
  ]
end

include_recipe 'gitlab-haproxy::internal_0_temporary_hacks'
include_recipe 'apt::unattended-upgrades'

env = node.chef_environment

# rubocop:disable Chef/Modernize # Chef 15 adds helpers cookstyle wants to use here
if ENV['TEST_KITCHEN']
  # Because kitchen now mocks the production attributes, we need to set this. Otherwise this will be `_default`.
  env = 'gprd'
end

# rubocop:disable Chef/Modernize # Chef 15 adds helpers cookstyle wants to use here
node.default['gitlab-haproxy']['secrets'] = {
    backend: 'hashicorp_vault',
    path: {
      path: "env/#{env}/cookbook/gitlab-haproxy/frontend-loadbalancer",
      mount: 'chef',
    },
} if !node['cloud'].nil? && node['cloud']['provider'] == 'gce'

# The run_state is a global hash, but it's never saved anywhere.
node.run_state['HAP_secrets'] = gitlab_haproxy_secrets['gitlab-haproxy']

include_recipe 'gitlab-haproxy::internal_1_certificates'

# ---------------------------------------- region set required node attributes ----------------------------------------
# rubocop:disable Chef/Modernize # Chef 15 adds helpers cookstyle wants to use here
if !node['cloud'].nil? && node['cloud']['provider'] == 'gce'
  node.default['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = true
  node.default['gitlab-haproxy']['frontend']['asset_proxy']['host'] = "gitlab-#{env}-assets.storage.googleapis.com"
  node.default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_host'] = "gitlab-#{env}-assets.storage.googleapis.com"
end

node.default['gitlab-haproxy']['ci-gateway']['allowlisted_runner_managers'] = ['10.0.0.0/8'] if node['gitlab-haproxy']['ci-gateway']['allowlisted_runner_managers'].empty?
eth = node['network']['interfaces'].select { |_k, v| v['encapsulation'] == 'Ethernet' }.values.first
node.default['gitlab-haproxy']['api_address'] = eth['addresses'].detect { |_k, v| v[:family] == 'inet' }.first
# ---------------------------------------- endregion set required node attributes ----------------------------------------

# Attribute mapping for backwards compatibility
node.default['gitlab-haproxy']['main'] = node['gitlab-haproxy']['frontend']

%w(blocklist-uris canary-request-paths allowlist-api allowlist-internal).each do |list|
  template "/etc/haproxy/#{list}.lst" do
    source "lists/#{list}.lst.erb"
    mode '0600'
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end
end

%w(/etc/haproxy/errors /etc/haproxy/scripts).each do |dir|
  directory dir do
    mode '0700'
    recursive true
  end
end

template '/etc/haproxy/scripts/ci-gateway-redirect.lua' do
  source 'ci-gateway-redirect.lua.erb'
  mode '0600'
  helpers(Gitlab::TemplateHelpers)
  notifies :run, 'execute[test-haproxy-config]', :delayed
  only_if { node['gitlab-haproxy']['ci-gateway']['redirect_using_lua'] }
end

%w(400 403 429 500 502 504 bad_ref).each do |code|
  cookbook_file "/etc/haproxy/errors/#{code}.http" do
    source "haproxy-errors-#{code}.http"
  end
end

template '/etc/haproxy/errors/503.http' do
  source 'haproxy-errors-503.http.erb'
end

git '/etc/haproxy/front-end-security' do
  repository node.run_state['HAP_secrets']['front-end-security']['git_https']
  revision 'master'
  action :sync
  notifies :run, 'execute[test-haproxy-config]', :delayed
  timeout 15
  ignore_failure true
end

cookbook_file '/etc/haproxy/ssl/cf-origin-pull.ca' do
  source 'origin-pull-ca.pem'
  sensitive true
  owner 'root'
  group 'root'
  mode '0600'
  action :create
  notifies :run, 'execute[test-haproxy-config]', :delayed
end

%w(v4 v6).each do |ipv|
  remote_file "/etc/haproxy/cloudflare_ips_#{ipv}.lst" do
    source "https://www.cloudflare.com/ips-#{ipv}"
    mode '0644'
    atomic_update true
    retries 3
    action :create
    notifies :run, 'execute[test-haproxy-config]', :delayed

    # Prevent an update and reload on every chef-run
    # Since cloudlfare sets an etag we can use that.
    use_conditional_get true
    use_etag true
  end
end

package 'socat'

# #################### LEGACY CODE ####################
# This script is kept, because it does not hurt, but it is unknown who might use it.
# It is no longer used for HAProxy 2.6, as draining now starts immediately after the process was signaled.
# Before HAProxy 2.4, HAProxy used to wait for a last request and response to add a "connection: close" header before closing.
# This made draining very ineffective.
#
# This is the behaviour this script avoids, by forcing the GCP LB to drop traffic to the node.
# But again, because HAProxy will automatically close frontend connections now, this means:
#   1. if HAProxy is restarting, the old process will stop listeing, but a new one will already accept the new request
#   2. if HAProxy is stopping, the old process will stop listening, also dropping health checks for GCP.
cookbook_file '/usr/local/sbin/drain_haproxy.sh' do
  source 'drain_haproxy.sh'
  owner 'root'
  group 'root'
  mode '0750'
end

include_recipe 'gitlab-haproxy::internal_2_sysctl'
include_recipe 'gitlab-haproxy::internal_3_logrotate'
include_recipe 'gitlab-haproxy::internal_4_monitoring'

node.run_state['HAP_prerequisites_included'] = true
