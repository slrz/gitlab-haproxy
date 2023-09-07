#
# Cookbook:: gitlab-haproxy
# Recipe:: certificates
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

haproxy_secrets = node.run_state['HAP_secrets']

directory '/etc/haproxy/ssl' do
  mode '0700'
  recursive true
end

case node['gitlab-haproxy']['flavor']
when 'main'
  file '/etc/haproxy/ssl/gitlab.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['gitlab_crt']}\n#{haproxy_secrets['ssl']['gitlab_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  file '/etc/haproxy/ssl/internal.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['internal_crt']}\n#{haproxy_secrets['ssl']['internal_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  file '/etc/haproxy/ssl/ci-gateway.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['ci_gateway_crt']}\n#{haproxy_secrets['ssl']['ci_gateway_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  file '/etc/haproxy/ssl/kas.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['kas_crt']}\n#{haproxy_secrets['ssl']['kas_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  # We may still need to use the old configurations on new HAProxy 2.8 nodes.
  # TODO: This can only be removed after we successfully migrated to the new configs run by HAProxy 2.8.
  # See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
  if node['lsb']['codename'] == 'bionic' || node['gitlab-haproxy']['use_old_config']
    # The canary.gitlab.com domain is not used anymore, but this is still configured for HAProxy 1.8
    file '/etc/haproxy/ssl/canary.pem' do
      sensitive true
      mode '0600'
      content "#{haproxy_secrets['ssl']['canary_crt']}\n#{haproxy_secrets['ssl']['canary_key']}\n"
      notifies :run, 'execute[test-haproxy-config]', :delayed
    end
  end
when 'registry'
  file '/etc/haproxy/ssl/registry.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['registry_crt']}\n#{haproxy_secrets['ssl']['registry_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end

  file '/etc/haproxy/ssl/internal.pem' do
    sensitive true
    mode '0600'
    content "#{haproxy_secrets['ssl']['internal_crt']}\n#{haproxy_secrets['ssl']['internal_key']}\n"
    notifies :run, 'execute[test-haproxy-config]', :delayed
  end
when 'pages'
  # No certificate
else
  raise 'unsupported flavor!'
end
