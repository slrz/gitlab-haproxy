#
# Cookbook:: gitlab-haproxy
# Recipe:: agent
#
# Copyright:: (C) 2026 GitLab Inc.
#
# License: MIT
#
# Installs gitlab-haproxy-agent, the agent-check responder for the HAProxy
# control plane. haproxy asks it about every backend server on a short
# interval and it answers with the desired admin state held in consul KV.
# https://gitlab.com/gitlab-com/gl-infra/gitlab-haproxy-agent

agent = node['gitlab-haproxy']['agent']
tarball = "#{Chef::Config['file_cache_path']}/gitlab-haproxy-agent_#{agent['version']}_Linux_x86_64.tar.gz"
install_root = '/opt/gitlab-haproxy-agent'
install_dir = "#{install_root}/#{agent['version']}"

if agent['enable']
  download_headers = {}

  if agent['use_deploy_token']
    env = node.chef_environment == '_default' ? 'gprd' : node.chef_environment
    token_secret = get_secrets('hashicorp_vault',
                               { 'path' => "env/#{env}/cookbook/gitlab-haproxy/agent", 'mount' => 'chef' },
                               nil)
    download_headers['DEPLOY-TOKEN'] = token_secret['token']
  end

  remote_file tarball do
    source "#{agent['download_url_base']}/#{agent['version']}/gitlab-haproxy-agent_#{agent['version']}_Linux_x86_64.tar.gz"
    headers download_headers
    checksum agent['checksum']
    mode '0644'
    retries 3
    sensitive true
  end

  directory install_dir do
    recursive true
  end

  execute 'extract-gitlab-haproxy-agent' do
    command "tar -C #{install_dir} -xzf #{tarball} gitlab-haproxy-agent"
    creates "#{install_dir}/gitlab-haproxy-agent"
  end

  link '/usr/local/bin/gitlab-haproxy-agent' do
    to "#{install_dir}/gitlab-haproxy-agent"
  end

  systemd_unit 'gitlab-haproxy-agent.service' do
    content <<~UNIT
      [Unit]
      Description=Agent-check responder for the HAProxy control plane
      Documentation=https://gitlab.com/gitlab-com/gl-infra/gitlab-haproxy-agent
      After=network-online.target consul.service
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/gitlab-haproxy-agent \\
        --listen-addr #{agent['listen_addr']} \\
        --monitoring-addr #{agent['monitoring_addr']} \\
        --pprof-addr #{agent['pprof_addr']} \\
        --kv-prefix #{agent['kv_prefix']}
      # The agent exits when consul is unreachable at startup and relies on
      # being restarted until the first sync succeeds.
      Restart=always
      RestartSec=2
      StartLimitIntervalSec=0
      DynamicUser=yes
      NoNewPrivileges=yes
      ProtectSystem=strict
      ProtectHome=yes

      [Install]
      WantedBy=multi-user.target
    UNIT
    triggers_reload true
    action :create
  end

  service 'gitlab-haproxy-agent' do
    action %i(enable start)
    subscribes :restart, 'systemd_unit[gitlab-haproxy-agent.service]', :delayed
    subscribes :restart, 'link[/usr/local/bin/gitlab-haproxy-agent]', :delayed
  end
else
  systemd_unit 'gitlab-haproxy-agent.service' do
    triggers_reload true
    action %i(stop disable delete)
  end

  link '/usr/local/bin/gitlab-haproxy-agent' do
    action :delete
  end

  directory install_root do
    recursive true
    action :delete
  end

  file tarball do
    action :delete
  end
end
