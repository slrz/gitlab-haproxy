#
# Cookbook:: gitlab-haproxy
# Recipe:: certificates
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT

haproxy_secrets = node.run_state['HAP_secrets']

directory '/etc/haproxy/ssl' do
  mode '0700'
  recursive true
end

case node['gitlab-haproxy']['flavor']
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

  if node['lsb']['codename'] == 'bionic'
    # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839

    # The canary.gitlab.com domain is not used anymore, thus this cert is useless. But it's still configured for HAP 1.8
    file '/etc/haproxy/ssl/canary.pem' do
      sensitive true
      mode '0600'
      content "#{haproxy_secrets['ssl']['canary_crt']}\n#{haproxy_secrets['ssl']['canary_key']}\n"
      notifies :run, 'execute[test-haproxy-config]', :delayed
    end
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
when 'pages'
  # no certificates
else
  raise 'unsupported flavor!'
end
