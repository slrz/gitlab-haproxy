### Save HAProxy state on reload
default['gitlab-haproxy']['systemd_service_overrides']['enable'] = true
default['gitlab-haproxy']['drain_time_seconds'] = 600
default['gitlab-haproxy']['systemd_timeout_stop_seconds'] = (node['gitlab-haproxy']['drain_time_seconds'] * 1.25).to_i

default['gitlab-haproxy']['secrets']['backend'] = 'chef_vault'
default['gitlab-haproxy']['secrets']['path'] = 'gitlab-cluster-base'
default['gitlab-haproxy']['secrets']['key'] = '_default'

default['gitlab-haproxy']['errors']['503']['title'] = 'An internal server error occured.'
default['gitlab-haproxy']['errors']['503']['subtitle'] = 'Please see our <a href="https://status.gitlab.com">status page</a> for more information.'
default['gitlab-haproxy']['global']['ssl-default-bind-ciphers'] = 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!3DES'
default['gitlab-haproxy']['global']['ssl-default-bind-options'] = nil

### Multithreading configuration #####
default['gitlab-haproxy']['global']['multithreading']['enable'] = false
#   nbproc should never be changed, we need 1 process for our stick tables
#   By default, only one process is created, which is the recommended mode
#   of operation.
default['gitlab-haproxy']['global']['multithreading']['nbproc'] = '1'
#   It creates <number> threads for each created processes.
#   this defaults to 4 on the current HAProxy fleet, 1 thread per core
default['gitlab-haproxy']['global']['multithreading']['nbthread'] = node['cpu']['total']
######################################

# https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#3.1-hard-stop-after
# Kill connections that remain open when HAProxy receives a SIGUSR1
# this helps to prevent presistent TCP connections from keeping haproxy
# processes lingering for a long time after reload
default['gitlab-haproxy']['global']['hard-stop']['enable'] = false
default['gitlab-haproxy']['global']['hard-stop']['timeout'] = '30m'
default['gitlab-haproxy']['global']['tcp_checks'] =
  [
    {
      'port' => '8083',
      'path' => '/readiness',
    },
    {
      'port' => '443',
      'ssl' => true,
      'path' => '/-/health',
    },
  ]
default['gitlab-haproxy']['delay_speed_ms'] = '1000'
default['gitlab-haproxy']['timeout_connect'] = '5000'
default['gitlab-haproxy']['timeout_check'] = '30000'
default['gitlab-haproxy']['timeout_server_ssh'] = '2h'
default['gitlab-haproxy']['timeout_server_camoproxy'] = '10s'
default['gitlab-haproxy']['timeout_client_fin'] = '5s'
default['gitlab-haproxy']['timeout_server_fin'] = '5s'
default['gitlab-haproxy']['timeout_tunnel'] = '8s'
default['gitlab-haproxy']['listen_address'] = '0.0.0.0'
default['gitlab-haproxy']['timeout_client'] = '90s'
default['gitlab-haproxy']['timeout_server'] = '90s'
default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['api_address'] = '0.0.0.0'
default['gitlab-haproxy']['maxconn'] = '20000'

default['gitlab-haproxy']['frontend']['blacklist']['uri'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['internal'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['api'] = {}

default['gitlab-haproxy']['frontend']['peers']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['api']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['api']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['rate_limit_http_rate_per_minute'] = '600'
default['gitlab-haproxy']['frontend']['api']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['api']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['https_git']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['https_git']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['https_git']['servers'] = {}
default['gitlab-haproxy']['frontend']['https']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['https']['rate_limit_frontend_port'] = '4444'
default['gitlab-haproxy']['frontend']['https']['rate_limit_sessions_per_second'] = '10'
default['gitlab-haproxy']['frontend']['https']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['frontend']['https']['extra_bind_port'] = nil

default['gitlab-haproxy']['frontend']['ssh']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ssh']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['ssh']['check_opts'] = 'check-ssl port 443 verify none'
default['gitlab-haproxy']['frontend']['ssh']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['ssh']['port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['servers'] = {}
default['gitlab-haproxy']['frontend']['ssh']['custom_config'] = []

default['gitlab-haproxy']['frontend']['web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['web']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['web']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['web']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['web']['content_security_policy_enabled'] = true
default['gitlab-haproxy']['frontend']['web']['content_security_policy'] = " default-src 'self';"
# Access control headers disabled because of https://gitlab.com/gitlab-com/gl-infra/production/issues/724
default['gitlab-haproxy']['frontend']['web']['access_control_allow_headers']['enable'] = false
default['gitlab-haproxy']['frontend']['web']['access_control_allow_headers']['headers'] = ' X-Requested-With'
default['gitlab-haproxy']['frontend']['web']['servers'] = {}
default['gitlab-haproxy']['frontend']['web_runoff']['servers'] = {}

default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy_enabled'] = true
default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy'] = " default-src 'self';"
default['gitlab-haproxy']['frontend']['websockets']['servers'] = {}
default['gitlab-haproxy']['frontend']['websockets']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['websockets']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['websockets']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['websockets']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['api_rate_limit']['custom_config'] = []
default['gitlab-haproxy']['frontend']['api_rate_limit']['enforced'] = true
default['gitlab-haproxy']['frontend']['default_check_opts'] = 'inter 2s fastinter 1s downinter 5s fall 3'
default['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = false
default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_path'] = '/info'
default['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'example.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['server'] = 'storage.googleapis.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['opts'] = 'check check-ssl inter 2s fastinter 1s downinter 5s fall 3 ssl verify none'
default['gitlab-haproxy']['frontend']['use_weights'] = false

default['gitlab-haproxy']['frontend']['web']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['web_runoff']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['api']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['ssh']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['ssh']['server_port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['balance'] = 'source'
default['gitlab-haproxy']['frontend']['https_git']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['websockets']['default_weight'] = '100'

default['gitlab-haproxy']['frontend']['canary_web']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_api']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_https_git']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_registry']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_web']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_api']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_ssh']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_https_git']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_websockets']['default_weight'] = '0'

default['gitlab-haproxy']['frontend']['canary_web']['servers'] = {}
default['gitlab-haproxy']['frontend']['canary_api']['servers'] = {}
default['gitlab-haproxy']['frontend']['canary_ssh']['servers'] = {}
default['gitlab-haproxy']['frontend']['canary_https_git']['servers'] = {}
default['gitlab-haproxy']['frontend']['canary_websockets']['servers'] = {}

default['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = []

default['gitlab-haproxy']['frontend']['root_page_redirect']['enable'] = false
default['gitlab-haproxy']['frontend']['root_page_redirect']['url'] = 'https://about.gitlab.com'
default['gitlab-haproxy']['frontend']['root_page_redirect']['session_cookie'] = '_gitlab_session'
default['gitlab-haproxy']['frontend']['root_page_redirect']['status_code'] = '301'

default['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull'] = false

default['gitlab-haproxy']['altssh']['custom_config'] = nil
default['gitlab-haproxy']['altssh']['servers'] = {}
default['gitlab-haproxy']['altssh']['balance'] = 'source'

default['gitlab-haproxy']['pages']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['pages']['httpchk_path'] = '/-/readiness'
default['gitlab-haproxy']['pages']['http_custom_config'] = nil
default['gitlab-haproxy']['pages']['https_custom_config'] = nil
default['gitlab-haproxy']['pages']['servers'] = {}
default['gitlab-haproxy']['pages']['http_backend_listen_port'] = 1080
default['gitlab-haproxy']['pages']['https_backend_listen_port'] = 1443
default['gitlab-haproxy']['pages']['enable_domain_blacklisting'] = false

default['gitlab-haproxy']['registry']['servers'] = {}
default['gitlab-haproxy']['canary_registry']['servers'] = {}
default['gitlab-haproxy']['registry']['peers']['servers'] = {}
default['gitlab-haproxy']['registry']['custom_config'] = nil
default['gitlab-haproxy']['registry']['backend_port'] = '5000'
default['gitlab-haproxy']['registry']['httpchk_host'] = 'registry.gitlab.com'
default['gitlab-haproxy']['registry']['httpchk_path'] = '/debug/health'
default['gitlab-haproxy']['registry']['default_check_opts'] = 'inter 2s fastinter 1s downinter 5s fall 3 port 5001'
default['gitlab-haproxy']['registry']['use_weights'] = false
default['gitlab-haproxy']['registry']['default_weight'] = '100'
default['gitlab-haproxy']['gke_registry']['default_weight'] = '0'
default['gitlab-haproxy']['gke_registry']['servers'] = {}

default['gitlab-haproxy']['registry']['enforce_cloudflare_origin_pull'] = false

default['gitlab-haproxy']['camoproxy']['server_port'] = 8080
default['gitlab-haproxy']['camoproxy']['httpchk_path'] = '/status'

default['gitlab-haproxy']['cloudflare']['enable'] = false
default['gitlab-haproxy']['cloudflare']['origin_pull']['certificate_source'] = 'https://support.cloudflare.com/hc/en-us/article_attachments/360044928032/origin-pull-ca.pem'
