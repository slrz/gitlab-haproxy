#
# Cookbook:: gitlab-haproxy
# Recipe:: install_and_configure
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

raise "need to include #{cookbook_name}::prerequisites before #{cookbook_name}::install" unless node.run_state['HAP_prerequisites_included']

if node['lsb']['codename'] == 'bionic'
  # Compatibility with old deployments. This will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
  apt_repository 'haproxy' do
    uri "ppa:vbernat/#{node['gitlab-haproxy']['major-version']}"
  end

  package 'hatop' # This is an ancient version (0.7.7) from 2010
else
  # Install HAProxy 2.6 LTS. Supported until April 2027
  apt_repository 'haproxy' do
    uri 'ppa:vbernat/haproxy-2.6'
  end

  package 'python-is-python3' # required, as hatop only invokes `python`, and ubuntu ships with `python3`. This package creates a symlink.

  # jhunt maintains hatop now. Just a python script. Updated this year.
  remote_file '/usr/local/bin/hatop' do
    source 'https://github.com/jhunt/hatop/releases/download/v0.8.2/hatop'
    mode '0755'
    atomic_update true
    retries 3
    action :create

    use_conditional_get true
    use_etag true
  end
end

service 'haproxy' do
  supports [:reload]
end

service 'rsyslog' do
  supports [:restart]
end

package 'haproxy' do
  # We restart rsyslog in order to create the socket HAProxy logs to
  # TODO: This *might* be unnecessary on 20.04+, as we log *through* systemd to rsyslog
  notifies :restart, 'service[rsyslog]', :delayed
end

execute 'test-haproxy-config' do
  command 'haproxy -c -f /etc/haproxy/haproxy.cfg'
  notifies :reload, 'service[haproxy]', :delayed
  action :nothing
end

if node['lsb']['codename'] != 'bionic'
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
end
