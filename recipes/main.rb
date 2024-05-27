#
# Cookbook:: gitlab-haproxy
# Recipe:: main
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

# Check if HAProxy should be configured based on the condition currently the HAProxy toggle is only defined for gstg
if (node['haproxy'].nil?) || (node['haproxy']['enabled'] && node.chef_environment == 'gstg')

  node.default['gitlab-haproxy']['flavor'] = 'main'

  include_recipe 'gitlab-haproxy::prerequisites'

  git '/etc/haproxy/recaptcha' do
    repository node.run_state['HAP_secrets']['recaptcha']['git_https']
    action :sync
    notifies :run, 'execute[test-haproxy-config]', :delayed
    timeout 15
    ignore_failure true
  end

  include_recipe 'gitlab-haproxy::install'

  # CI gateway frontends and backends have to be disabled in pre environment
  unless node['gitlab-haproxy']['ci-gateway']['enabled']
    node.default['gitlab-haproxy']['enabled_frontends']['main'].delete('https_git_ci_gateway')
    node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_catch_all')
    node.default['gitlab-haproxy']['enabled_backends']['main'].delete('ci_gateway_git_repo_redirection')
  end

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

else
  log 'HAProxy is disabled' do
    level :info
  end
end
