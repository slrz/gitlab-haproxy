#### This file is currently heavily worked on.
# Any attribute suffixed with a `# legacy` comment, will be removed after https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
# The old verbiage `frontend` (meaning the main HAProxy fleet, not the frontend of HAProxy) is deprecated and replaced with `main`.
# E.g. fe-01-lb-gprd is a node in the `main` fleet of HAProxy nodes.

default['gitlab-haproxy']['flavor'] = nil # This determines whether it will become 'main', 'pages', or 'registry'
default['gitlab-haproxy']['use_old_config'] = false

# This is a list of enabled backends. This means they are present in the rendered configuration, not necessarily that there is traffic routed towards them.
default['gitlab-haproxy']['enabled_backends']['main'] = %w(asset_proxy api main_api ai_assisted https_git web main_web canary_web canary_https_git canary_api kas kas_k8s_proxy canary_kas canary_kas_k8s_proxy ssh websockets ci_gateway_catch_all ci_gateway_git_repo_redirection)
default['gitlab-haproxy']['enabled_backends']['registry'] = %w(registry canary_registry)
default['gitlab-haproxy']['enabled_backends']['pages'] = %w(pages_https pages_http)

# This is a list of enabled frontends. This means they are present in the rendered configuration.
# Please see `templates/frontend/<name>.erb for details on the frontend.`
# Please enable check_* frontends by setting a backend on `check_frontends` below.
default['gitlab-haproxy']['enabled_frontends']['main'] = %w(http https kas ssh https_git_ci_gateway)
default['gitlab-haproxy']['enabled_frontends']['registry'] = %w(http https) # These backends are flavored.
default['gitlab-haproxy']['enabled_frontends']['pages'] = %w(pages_http pages_https) # Explicitly enable the check_* variants as their name does not match.

# This is the check_* frontend configuration
# If a check_* frontend has no backends to check, it will not be rendered.
# By default no check_* frontend will have backends. These are set in the flavors. This is to allow maximum flexibility without duplication.
#
#                                              |--------This is the flavor. Specifics will override `default`.
#                                              |          |- The check frontend to enable
#                                              V          V            V- `backends`(array of backends required to be available), `uri` (`monitor uri` value), `port` Listen port
# default URIs
default['gitlab-haproxy']['check_frontends']['default']['check_http']['uri'] = '/-/available-http'
default['gitlab-haproxy']['check_frontends']['default']['check_https']['uri'] = '/-/available-https'
default['gitlab-haproxy']['check_frontends']['default']['check_ssh']['uri'] = '/-/available-ssh'
# default ports:
default['gitlab-haproxy']['check_frontends']['default']['check_http']['port'] = 8001
default['gitlab-haproxy']['check_frontends']['default']['check_https']['port'] = 8002
default['gitlab-haproxy']['check_frontends']['default']['check_ssh']['port'] = 8003
# main flavor overrides
default['gitlab-haproxy']['check_frontends']['main']['check_http']['backends'] = %w(web)
default['gitlab-haproxy']['check_frontends']['main']['check_https']['backends'] = %w(web api)
default['gitlab-haproxy']['check_frontends']['main']['check_ssh']['backends'] = %w(ssh)
# pages flavor overrides
default['gitlab-haproxy']['check_frontends']['pages']['check_http']['backends'] = %w(pages_http)
default['gitlab-haproxy']['check_frontends']['pages']['check_https']['backends'] = %w(pages_https)
# registry flavor overrides
default['gitlab-haproxy']['check_frontends']['registry']['check_http']['backends'] = %w(registry)
default['gitlab-haproxy']['check_frontends']['registry']['check_https']['backends'] = %w(registry)

# This will determine the HAProxy configuration options (2.8+ only)
# Some values are not changeable via attributes by design.
# HAProxy 2.8 configuration documentation: https://docs.haproxy.org/2.8/configuration.html
#
# Timeouts are statically set in the defaults section by design.
# If they should be adjusted, it MUST be done in the backend configuration. Generally they should not be changed,
# unless there is a very good reason, and you're sure of what changing the timeout in question does.
#
#                                      |--------This is the flavor. Specifics will override `default`.
#                                      |          |- this is the area `global`/`defaults`
#                                      V          V            V- this is the config value. Set this to `nil` to remove it when overriding. Otherwise this can be an empty string, number, or even a comment (with # prefix)
# Default global section:
default['gitlab-haproxy']['config']['default']['global']['no-memory-trimming'] = '' # Disables `malloc_trim`, which can be very slow if handling 10k connections+ because of memory fragmentation.
default['gitlab-haproxy']['config']['default']['global']['ssl-mode-async'] = '' # Enables asynchronous TLS engine usage during initial and renegotiation handshakes.
default['gitlab-haproxy']['config']['default']['global']['tune.ssl.lifetime'] = 900 # A TLS session can be resumed within 15 minutes if the cache did not evict the idle connection.
default['gitlab-haproxy']['config']['default']['global']['spread-checks'] = 4 # spread of health-checks.
default['gitlab-haproxy']['config']['default']['global']['hard-stop-after'] = '30m' # Any open connections will be killed after this time, when in a soft-stop state.
# Default defaults section
default['gitlab-haproxy']['config']['default']['defaults']['retries'] = '3' # Retry to establish a session to a backend server 3 times. (NOT REQUESTS. If a session is established between client and backend server, there will not be any retries).
default['gitlab-haproxy']['config']['default']['defaults']['retry-on'] = 'conn-failure' # `conn-failure` is the default, but since it might change, we statically set it, to ensure consistency going forward.
default['gitlab-haproxy']['config']['default']['defaults']['option redispatch'] = 1 # redistribute a session if a backend server is unavailable after 1 retry
default['gitlab-haproxy']['config']['default']['defaults']['option splice-auto'] = '' # Instead of specifying this in every frontend, set it in defaults.
default['gitlab-haproxy']['config']['default']['defaults']['option tcpka'] = '' # Enable TCP keepalive. Useful for HTTPS-git requests, that might have long delays between data bursts.
default['gitlab-haproxy']['config']['default']['defaults']['option tcp-smart-connect'] = '' # Ask the kernel to directly send data to HAProxy. Saves context switches, as data is immediately available.
# main flavor overrides
# pages flavor overrides
default['gitlab-haproxy']['config']['pages']['global']['ssl-mode-async'] = nil # We don't do TLS on pages, and this might interfere with the inspect delay.
default['gitlab-haproxy']['config']['pages']['defaults']['option redispatch'] = nil # TLS is not terminated on the pages LBs, so this is useless.
# registry flavor overrides

# Similarly to above, you can also set frontend/backend options:
#
#                                      |--------This is the flavor. Specifics will override `default`.
#                                      |          |- `frontend`/`backend`
#                                      V          V           |- frontend/backend name
#                                      V          V           V               V- this is the config value. Setting to nil will not disable any settings from defaults.
# main flavor overrides:
default['gitlab-haproxy']['config']['main']['backend']['canary_https_git']['timeout server'] = '1h # Because HTTPS-git requests might take very long to process (packing commits), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas_k8s_proxy']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas_k8s_proxy']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['https_git']['timeout server'] = '1h # Because HTTPS-git requests might take very long to process (packing commits), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['kas']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['kas']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['kas_k8s_proxy']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['kas_k8s_proxy']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['ssh']['no option redispatch'] = '# Redispatching a TLS connection does not make sense. This would only happen after a connection was established, so the tunnel would be dead anyways.'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['cookie _gitlab_session'] = 'prefix nocache'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['option http-server-close'] = '# Copied from old config. But why do we need this?'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['timeout tunnel'] = '8s' # copied from default['gitlab-haproxy']['timeout_tunnel'] = '8s'
default['gitlab-haproxy']['config']['main']['frontend']['kas']['timeout client'] = '1h # KAS specific tuning for SPDY'

# New healthcheck config only used in HAProxy 2.8+
default['gitlab-haproxy']['registry']['health_check']['httpchk_host'] = 'registry.gitlab.com'
# According to https://github.com/distribution/distribution/issues/629#issuecomment-112222118 the /v2/ endpoint is either 401 or 200 if registry is functional.
default['gitlab-haproxy']['registry']['health_check']['httpchk_path'] = '/v2/'
default['gitlab-haproxy']['registry']['health_check']['httpchk_status'] = '200-299,401'
default['gitlab-haproxy']['registry']['health_check']['tcp_check_enable'] = false

# Explicit overrides to fix issues with default attributes.
# TODO: Move to `default` in https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/868
# Once attributes from `frontend` are merged into `main` (what the `temporary_hacks` recipe is doing on the fly now)
# this can just become the `default` config, so we do not need to override this via `normal` anymore.
normal['gitlab-haproxy']['main']['ssh']['check_opts'] = 'no-ssl'
normal['gitlab-haproxy']['main']['ssh']['ssl_verify'] = 'no-ssl'
normal['gitlab-haproxy']['main']['ssh']['tcp_check_enable'] = true
normal['gitlab-haproxy']['main']['ssh']['tcp_check_string'] = 'SSH-2.0'

############## Old/inherited attributes below!

default['gitlab-haproxy']['major-version'] = 'haproxy-1.8' # legacy

### Save HAProxy state on reload
default['gitlab-haproxy']['systemd_service_overrides']['enable'] = true # legacy
default['gitlab-haproxy']['drain_time_seconds'] = 600 # legacy
default['gitlab-haproxy']['systemd_timeout_stop_seconds'] = (node['gitlab-haproxy']['drain_time_seconds'] * 1.25).to_i # legacy

default['gitlab-haproxy']['secrets']['backend'] = 'hashicorp_vault'
default['gitlab-haproxy']['secrets']['path'] = 'gitlab-cluster-base'

default['gitlab-haproxy']['errors']['503']['title'] = 'An internal server error occured.'
default['gitlab-haproxy']['errors']['503']['subtitle'] = 'Please see our <a href="https://status.gitlab.com">status page</a> for more information.'
default['gitlab-haproxy']['global']['extra-default-bind-ciphers'] = '' # legacy
default['gitlab-haproxy']['global']['ssl-default-bind-ciphers'] = 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!3DES' # legacy
default['gitlab-haproxy']['global']['ssl-default-bind-options'] = 'no-tlsv10 no-tlsv11' # legacy

### Multithreading configuration #####
#   It creates <number> threads for each created processes.
#   this defaults to 4 on the current HAProxy fleet, 1 thread per core
default['gitlab-haproxy']['global']['nbthread'] = node['cpu']['total'] # legacy
######################################

# https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#3.1-hard-stop-after
# Kill connections that remain open when HAProxy receives a SIGUSR1
# this helps to prevent presistent TCP connections from keeping haproxy
# processes lingering for a long time after reload
default['gitlab-haproxy']['global']['hard-stop']['enable'] = true # legacy
default['gitlab-haproxy']['global']['hard-stop']['timeout'] = '30m' # legacy

default['gitlab-haproxy']['delay_speed_ms'] = '1000' # legacy
default['gitlab-haproxy']['timeout_connect'] = '5000' # legacy
default['gitlab-haproxy']['timeout_check'] = '30000' # legacy
default['gitlab-haproxy']['timeout_server_ssh'] = '2h' # legacy
default['gitlab-haproxy']['timeout_client_fin'] = '5s' # legacy
default['gitlab-haproxy']['timeout_server_fin'] = '5s' # legacy
default['gitlab-haproxy']['timeout_tunnel'] = '8s' # legacy
default['gitlab-haproxy']['listen_address'] = '0.0.0.0'
default['gitlab-haproxy']['timeout_client'] = '90s' # legacy
default['gitlab-haproxy']['timeout_server'] = '1h' # legacy
default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['api_address'] = '0.0.0.0'
default['gitlab-haproxy']['maxconn'] = 50000 # This value was hardcoded in 1.8 config

#####################################################################
#
# Fe lb configuration, gitlab.com port 443, 80, 22
# this is named "frontend" not to be confused with
# frontends in the HAProxy configuration file
#
#####################################################################

default['gitlab-haproxy']['frontend']['blacklist']['uri'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['internal'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['api'] = {}

default['gitlab-haproxy']['frontend']['peers']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['api']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['api']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['rate_limit_http_rate_per_minute'] = '600' # legacy
default['gitlab-haproxy']['frontend']['api']['rate_limit_package_registry_rate_per_minute'] = '7000' # legacy
default['gitlab-haproxy']['frontend']['api']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['api']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['api']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['api']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['https_git']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['https_git']['servers'] = {}
default['gitlab-haproxy']['frontend']['https_git']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['https_git']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['https_git']['use_verbose_acls'] = false

# These defaults are set so that we can have different defaults for the canary
# backend and can be removed once https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3465
# is complete, https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/merge_requests/272
default['gitlab-haproxy']['frontend']['canary_https_git']['httpchk_host'] = node['gitlab-haproxy']['frontend']['https_git']['httpchk_host']
default['gitlab-haproxy']['frontend']['canary_https_git']['httpchk_path'] = node['gitlab-haproxy']['frontend']['https_git']['httpchk_path']
default['gitlab-haproxy']['frontend']['canary_https_git']['check_opts'] = node['gitlab-haproxy']['frontend']['https_git']['check_opts']
default['gitlab-haproxy']['frontend']['canary_https_git']['tcp_check_enable'] = node['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable']
default['gitlab-haproxy']['frontend']['canary_https_git']['server_port'] = node['gitlab-haproxy']['frontend']['https_git']['server_port']
default['gitlab-haproxy']['frontend']['canary_https_git']['ssl_verify'] = node['gitlab-haproxy']['frontend']['https_git']['ssl_verify']

default['gitlab-haproxy']['frontend']['https']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['https']['rate_limit_frontend_port'] = '4444' # legacy
default['gitlab-haproxy']['frontend']['https']['rate_limit_sessions_per_second'] = '10' # legacy
default['gitlab-haproxy']['frontend']['https']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['frontend']['https']['api_ratelimit_bypass_for_useragent']['enable'] = false # legacy
default['gitlab-haproxy']['frontend']['https']['api_ratelimit_bypass_for_useragent']['useragent'] = nil # legacy
default['gitlab-haproxy']['frontend']['https']['extra_bind_port'] = nil
default['gitlab-haproxy']['frontend']['https']['enable_ratelimit_bypass_header'] = false # legacy
# Only has effect if the enable_ratelimit_bypass_header is also set to true
default['gitlab-haproxy']['frontend']['https']['enable_jwt_auth_ratelimit_bypass'] = false # legacy
default['gitlab-haproxy']['frontend']['https']['enable_package_registry_ratelimit_bypass'] = false # legacy
default['gitlab-haproxy']['frontend']['https']['enable_go_get_ratelimit_bypass'] = false # legacy

default['gitlab-haproxy']['kas']['enable'] = false
default['gitlab-haproxy']['kas']['timeout_http_keep_alive'] = '30s'
default['gitlab-haproxy']['kas']['timeout_tunnel'] = '2h'
default['gitlab-haproxy']['kas']['timeout_client'] = '1h'
default['gitlab-haproxy']['kas']['timeout_server'] = '1h'
default['gitlab-haproxy']['kas']['timeout_client_fin'] = '10s'
default['gitlab-haproxy']['frontend']['kas']['bind_options'] = 'ssl crt /etc/haproxy/ssl/kas.pem alpn h2,http/1.1,spdy/3.1' # legacy
default['gitlab-haproxy']['frontend']['kas']['bind_extra_options'] = 'alpn h2,http/1.1,spdy/3.1'
default['gitlab-haproxy']['frontend']['kas']['check_opts'] = 'port 8151'
default['gitlab-haproxy']['frontend']['kas']['check_port'] = 8151
default['gitlab-haproxy']['frontend']['kas']['timeout_http_request'] = '5s'
default['gitlab-haproxy']['frontend']['kas']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['kas']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['kas']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['kas']['httpchk_path'] = '/liveness'
default['gitlab-haproxy']['frontend']['kas']['port'] = '8150'
default['gitlab-haproxy']['frontend']['kas']['proxy_endpoint'] = '/k8s-proxy'
default['gitlab-haproxy']['frontend']['kas']['proxy_port'] = '8154'
default['gitlab-haproxy']['frontend']['kas']['server_port'] = '8150'
default['gitlab-haproxy']['frontend']['kas']['servers'] = {}
default['gitlab-haproxy']['frontend']['kas']['tcp_check_enable'] = false

default['gitlab-haproxy']['frontend']['canary_kas']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['canary_kas']['servers'] = {}

default['gitlab-haproxy']['frontend']['ssh']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ssh']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['ssh']['check_opts'] = 'check-ssl port 443 verify none'
default['gitlab-haproxy']['frontend']['ssh']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['ssh']['port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['server_port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['ssh']['servers'] = {}
default['gitlab-haproxy']['frontend']['ssh']['custom_config'] = []
default['gitlab-haproxy']['frontend']['ssh']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['ssh']['send-proxy-v2'] = false
default['gitlab-haproxy']['frontend']['canary_ssh']['send-proxy-v2'] = false

default['gitlab-haproxy']['frontend']['altssh']['send-proxy-v2'] = false
default['gitlab-haproxy']['frontend']['canary_altssh']['send-proxy-v2'] = false

default['gitlab-haproxy']['frontend']['web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['web']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['web']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['web']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['web']['content_security_policy_enabled'] = true # legacy
default['gitlab-haproxy']['frontend']['web']['content_security_policy'] = " default-src 'self';" # legacy
default['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only_enabled'] = false # legacy
default['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only'] = " default-src 'self';" # legacy
# Access control headers disabled because of https://gitlab.com/gitlab-com/gl-infra/production/issues/724
default['gitlab-haproxy']['frontend']['web']['access_control_allow_headers']['enable'] = false # legacy
default['gitlab-haproxy']['frontend']['web']['access_control_allow_headers']['headers'] = ' X-Requested-With' # legacy
default['gitlab-haproxy']['frontend']['web']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['web']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['web']['servers'] = {}
default['gitlab-haproxy']['frontend']['web_k8s']['servers'] = {}

# These defaults are set so that we can have different defaults for the canary
default['gitlab-haproxy']['frontend']['canary_web']['httpchk_host'] = node['gitlab-haproxy']['frontend']['web']['httpchk_host']
default['gitlab-haproxy']['frontend']['canary_web']['httpchk_path'] = node['gitlab-haproxy']['frontend']['web']['httpchk_path']
default['gitlab-haproxy']['frontend']['canary_web']['check_opts'] = node['gitlab-haproxy']['frontend']['web']['check_opts']
default['gitlab-haproxy']['frontend']['canary_web']['tcp_check_enable'] = node['gitlab-haproxy']['frontend']['web']['tcp_check_enable']
default['gitlab-haproxy']['frontend']['canary_web']['server_port'] = node['gitlab-haproxy']['frontend']['web']['server_port']
default['gitlab-haproxy']['frontend']['canary_web']['ssl_verify'] = node['gitlab-haproxy']['frontend']['web']['ssl_verify']

# These defaults are set so we that we can have different defaults for k8s nodes from web nodes in the web backend
default['gitlab-haproxy']['frontend']['web_k8s']['check_opts'] = node['gitlab-haproxy']['frontend']['web']['check_opts']
default['gitlab-haproxy']['frontend']['web_k8s']['server_port'] = node['gitlab-haproxy']['frontend']['web']['server_port']
default['gitlab-haproxy']['frontend']['web_k8s']['ssl_verify'] = node['gitlab-haproxy']['frontend']['web']['ssl_verify']

default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy_enabled'] = true # legacy
default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy'] = " default-src 'self';" # legacy
default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy_report_only_enabled'] = false # legacy
default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy_report_only'] = " default-src 'self';" # legacy
default['gitlab-haproxy']['frontend']['websockets']['servers'] = {}
default['gitlab-haproxy']['frontend']['websockets']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['websockets']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['websockets']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['websockets']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['websockets']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['websockets']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['ai_assisted']['servers'] = {}
default['gitlab-haproxy']['frontend']['ai_assisted']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['ai_assisted']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['ai_assisted']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ai_assisted']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['ai_assisted']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['ai_assisted']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['api_rate_limit']['custom_config'] = [] # legacy
default['gitlab-haproxy']['frontend']['api_rate_limit']['enforced'] = true # legacy
default['gitlab-haproxy']['frontend']['api_rate_limit']['package_registry_enforced'] = false # legacy
default['gitlab-haproxy']['frontend']['default_check_opts'] = 'inter 3s fastinter 1s downinter 5s fall 3'
default['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = false
default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_path'] = '/info'
default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_host'] = 'example.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'example.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['server'] = 'storage.googleapis.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['asset_proxy']['opts'] = 'check check-ssl inter 2s fastinter 1s downinter 5s fall 3 verify none resolve-prefer ipv4'

default['gitlab-haproxy']['frontend']['altssh']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['web']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['web_k8s']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['api']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['https_git']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['websockets']['default_weight'] = '100'

default['gitlab-haproxy']['frontend']['canary_web']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_api']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_https_git']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_registry']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_altssh']['default_weight'] = '0'
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

default['gitlab-haproxy']['frontend']['root_page_redirect']['enable'] = false # legacy
default['gitlab-haproxy']['frontend']['root_page_redirect']['url'] = 'https://about.gitlab.com' # legacy
default['gitlab-haproxy']['frontend']['root_page_redirect']['session_cookie'] = '_gitlab_session' # legacy
default['gitlab-haproxy']['frontend']['root_page_redirect']['status_code'] = '301' # legacy

default['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull'] = false

# Servers for HAProxy backends, defaulted to legacy server configuration that can
# be removed once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9766
# is complete
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['api'] = node['gitlab-haproxy']['frontend']['api']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['https_git'] = node['gitlab-haproxy']['frontend']['https_git']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['kas'] = node['gitlab-haproxy']['frontend']['kas']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_kas'] = node['gitlab-haproxy']['frontend']['canary_kas']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['ssh'] = node['gitlab-haproxy']['frontend']['ssh']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['web'] = node['gitlab-haproxy']['frontend']['web']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['web_k8s'] = node['gitlab-haproxy']['frontend']['web_k8s']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['websockets'] = node['gitlab-haproxy']['frontend']['websockets']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_web'] = node['gitlab-haproxy']['frontend']['canary_web']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_websockets'] = node['gitlab-haproxy']['frontend']['canary_websockets']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_api'] = node['gitlab-haproxy']['frontend']['canary_api']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_ssh'] = node['gitlab-haproxy']['frontend']['canary_ssh']['servers'] # legacy
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_https_git'] = node['gitlab-haproxy']['frontend']['canary_https_git']['servers'] # legacy

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['frontend']['backend']['essential'] = %w(api https_git ssh web websockets)
default['gitlab-haproxy']['frontend']['canonical_host'] = 'gitlab.com'

#####################################################################
#
# ALTSSH lb configuration, gitlab.com git-ssh on port 443
# No longer used!
#####################################################################

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['altssh']['backend']['essential'] = %w(altssh) # legacy
default['gitlab-haproxy']['canary_altssh']['backend']['essential'] = %w() # legacy

default['gitlab-haproxy']['altssh']['backend']['servers']['default']['altssh'] = {} # legacy
default['gitlab-haproxy']['altssh']['custom_config'] = nil # legacy
default['gitlab-haproxy']['canary_altssh']['backend']['servers']['default']['canary_altssh'] = {} # legacy

#####################################################################
#
# Pages lb configuration, *.gitlab.io port 443 and 80
#
#####################################################################
default['gitlab-haproxy']['pages']['default_weight'] = '100'
default['gitlab-haproxy']['pages']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['pages']['httpchk_path'] = '/-/readiness'
default['gitlab-haproxy']['pages']['http_custom_config'] = nil
default['gitlab-haproxy']['pages']['https_custom_config'] = nil
default['gitlab-haproxy']['pages']['servers'] = {}
default['gitlab-haproxy']['pages']['peers']['servers'] = {}
default['gitlab-haproxy']['pages']['http_backend_listen_port'] = 1080
default['gitlab-haproxy']['pages']['https_backend_listen_port'] = 1443
default['gitlab-haproxy']['pages']['https_proxyv2_backend_listen_port'] = 2443
default['gitlab-haproxy']['pages']['enable_https_proxyv2'] = false
default['gitlab-haproxy']['pages']['enable_domain_blacklisting'] = false
default['gitlab-haproxy']['pages']['enable_domain_rate_limiting'] = false
default['gitlab-haproxy']['pages']['domain_rate_limit_per_second'] = '800'
default['gitlab-haproxy']['canary_pages']['default_weight'] = '0'
default['gitlab-haproxy']['canary_pages']['http_backend_listen_port'] = node['gitlab-haproxy']['pages']['http_backend_listen_port']
default['gitlab-haproxy']['canary_pages']['https_backend_listen_port'] = node['gitlab-haproxy']['pages']['https_backend_listen_port']
default['gitlab-haproxy']['canary_pages']['https_proxyv2_backend_listen_port'] = node['gitlab-haproxy']['pages']['https_proxyv2_backend_listen_port']

# Servers for HAProxy backends, defaulted to legacy server configuration that can
# be removed once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9766
# is complete
default['gitlab-haproxy']['pages']['backend']['servers']['default']['pages'] = node['gitlab-haproxy']['pages']['servers'] # legacy
default['gitlab-haproxy']['pages']['backend']['servers']['default']['canary_pages'] = {} # legacy

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['pages']['backend']['essential'] = %w(pages)

#####################################################################
#
# Registry lb configuration, registry.gitlab.com port 443 and 80
#
#####################################################################

default['gitlab-haproxy']['registry']['servers'] = {}
default['gitlab-haproxy']['canary_registry']['servers'] = {}
default['gitlab-haproxy']['canary_registry']['default_weight'] = '0'
default['gitlab-haproxy']['registry']['peers']['servers'] = {}
default['gitlab-haproxy']['registry']['custom_config'] = nil
default['gitlab-haproxy']['registry']['backend_port'] = '5000'
default['gitlab-haproxy']['registry']['ssl_verify'] = nil
default['gitlab-haproxy']['registry']['httpchk_host'] = 'registry.gitlab.com'
default['gitlab-haproxy']['registry']['httpchk_path'] = '/debug/health'
default['gitlab-haproxy']['registry']['tcp_check_enable'] = false
default['gitlab-haproxy']['registry']['default_check_opts'] = 'inter 2s fastinter 1s downinter 5s fall 3 port 5001'
default['gitlab-haproxy']['registry']['default_weight'] = '100'

default['gitlab-haproxy']['registry']['enforce_cloudflare_origin_pull'] = false

default['gitlab-haproxy']['registry']['backend']['servers']['default']['registry'] = node['gitlab-haproxy']['registry']['servers'] # legacy
default['gitlab-haproxy']['registry']['backend']['servers']['default']['canary_registry'] = node['gitlab-haproxy']['canary_registry']['servers'] # legacy
# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['registry']['backend']['essential'] = %w(registry)

default['gitlab-haproxy']['cloudflare']['enable'] = false # legacy
default['gitlab-haproxy']['cloudflare']['ignore-proxy'] = false # legacy

default['gitlab-haproxy']['close_client_connections'] = false # legacy

default['gitlab-haproxy']['use_canary'] = true

default['gitlab-haproxy']['ci-gateway']['enabled'] = false
default['gitlab-haproxy']['ci-gateway']['listen_port'] = 8989
default['gitlab-haproxy']['ci-gateway']['allowlisted_runner_managers'] = []
default['gitlab-haproxy']['ci-gateway']['redirect_all_traffic_externally'] = false # legacy
default['gitlab-haproxy']['ci-gateway']['redirect_using_lua'] = false
