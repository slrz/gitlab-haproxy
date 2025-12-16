#### This file is currently heavily worked on.
# The old verbiage `frontend` (meaning the main HAProxy fleet, not the frontend of HAProxy) is deprecated.
# It is replaced with `main` in most places, but it is still used as `frontend` in attributes and runbooks.

# This determines whether it will become main, pages, or registry.
default['gitlab-haproxy']['flavor'] = nil

# If this attribute is set to true, it will be excluded from peering in other nodes config files
# when gitlab-haproxy.<flavor>.peers.dynamic_lookup is enabled.
default['gitlab-haproxy']['skip_peering'] = false
# If this attribute is set, the peer lookup will look for other nodes that possess this key instead of `flavor`
default['gitlab-haproxy']['peering_key'] = nil

# This is a list of enabled frontends.
# This means they are present in the rendered configuration.
# Please see `templates/frontend/<name>.erb for details on the frontend.`
# Please enable check_* frontends by setting a backend on `check_frontends` below.
default['gitlab-haproxy']['enabled_frontends']['main'] = %w(http https kas ssh https_git_ci_gateway)
default['gitlab-haproxy']['enabled_frontends']['pages'] = %w(pages_http pages_https)
default['gitlab-haproxy']['enabled_frontends']['registry'] = %w(http registry_https)

# This is a list of enabled backends.
# This means they are present in the rendered configuration, not necessarily that there is traffic routed to them.
default['gitlab-haproxy']['enabled_backends']['main'] = %w(asset_proxy api main_api ai_assisted canary_ai_assisted https_git web main_web canary_web canary_https_git canary_api kas kas_k8s_proxy canary_kas canary_kas_k8s_proxy ssh websockets ci_gateway_catch_all ci_gateway_git_repo_redirection)
default['gitlab-haproxy']['enabled_backends']['pages'] = %w(pages_https pages_http)
default['gitlab-haproxy']['enabled_backends']['registry'] = %w(registry canary_registry)

# This is the check_* frontend configuration
# If a check_* frontend has no backends to check, it will not be rendered.
# By default no check_* frontend will have backends. These are set in the flavors. This is to allow maximum flexibility without duplication.
#
#                                              |--------This is the flavor. Specifics will override `default`.
#                                              |          |- The check frontend to enable
#                                              |          |            |- `backends`(array of backends required to be available), `uri` (`monitor uri` value), `port` Listen port
#                                              V          V            V
# Default URIs
default['gitlab-haproxy']['check_frontends']['default']['check_http']['uri'] = '/-/available-http'
default['gitlab-haproxy']['check_frontends']['default']['check_https']['uri'] = '/-/available-https'
default['gitlab-haproxy']['check_frontends']['default']['check_ssh']['uri'] = '/-/available-ssh'
# Default ports:
default['gitlab-haproxy']['check_frontends']['default']['check_http']['port'] = 8001
default['gitlab-haproxy']['check_frontends']['default']['check_https']['port'] = 8002
default['gitlab-haproxy']['check_frontends']['default']['check_ssh']['port'] = 8003
# Main flavor overrides
default['gitlab-haproxy']['check_frontends']['main']['check_http']['backends'] = %w(web)
default['gitlab-haproxy']['check_frontends']['main']['check_https']['backends'] = %w(web api)
default['gitlab-haproxy']['check_frontends']['main']['check_ssh']['backends'] = %w(ssh)
# Pages flavor overrides
default['gitlab-haproxy']['check_frontends']['pages']['check_http']['backends'] = %w(pages_http)
default['gitlab-haproxy']['check_frontends']['pages']['check_https']['backends'] = %w(pages_https)
# Registry flavor overrides
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
#                                      |          |            |- this is the config value. Set this to `nil` to remove it when overriding. Otherwise this can be an empty string, number, or even a comment (with # prefix)
#                                      V          V            V
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
default['gitlab-haproxy']['config']['default']['defaults']['option dontlognull'] = '' # Don't log requests where no data flowed.
# main flavor overrides
# pages flavor overrides
default['gitlab-haproxy']['config']['pages']['global']['ssl-mode-async'] = nil # We don't do TLS on pages, and this might interfere with the inspect delay.
default['gitlab-haproxy']['config']['pages']['defaults']['option redispatch'] = nil # TLS is not terminated on the pages LBs, so this is useless.
# registry flavor overrides

# Similarly to above, you can also set frontend/backend options:
#
#                                      |--------This is the flavor. Specifics will override `default`.
#                                      |          |- `frontend`/`backend`
#                                      |          |           |- frontend/backend name
#                                      |          |           |               |- this is the config value. Setting to nil will not disable any settings from defaults.
#                                      V          V           V               V
# Main flavor overrides:
default['gitlab-haproxy']['config']['main']['backend']['canary_https_git']['timeout server'] = '1h # Because HTTPS-git requests might take very long to process (packing commits), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas_k8s_proxy']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['canary_kas_k8s_proxy']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['https_git']['timeout server'] = '1h # Because HTTPS-git requests might take very long to process (packing commits), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['main_api']['timeout server'] = '10m # Because some API requests might take very long to process (packages/generic), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['canary_api']['timeout server'] = '10m # Because some API requests might take very long to process (packages/generic), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['api']['timeout server'] = '10m # Because some API requests might take very long to process (packages/generic), we need to override the server timeout.'
default['gitlab-haproxy']['config']['main']['backend']['kas']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['kas']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['kas_k8s_proxy']['timeout server'] = '1h # KAS specific tuning for SPDY'
default['gitlab-haproxy']['config']['main']['backend']['kas_k8s_proxy']['timeout tunnel'] = '2h'
default['gitlab-haproxy']['config']['main']['backend']['ssh']['no option redispatch'] = '# Redispatching a TLS connection does not make sense. This would only happen after a connection was established, so the tunnel would be dead anyways.'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['cookie _gitlab_session'] = 'prefix nocache'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['option http-server-close'] = '# Copied from old config. But why do we need this?'
default['gitlab-haproxy']['config']['main']['backend']['websockets']['timeout tunnel'] = '8s'
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

default['gitlab-haproxy']['secrets']['backend'] = 'hashicorp_vault'
default['gitlab-haproxy']['secrets']['path'] = 'gitlab-cluster-base'

default['gitlab-haproxy']['errors']['503']['title'] = 'An internal server error occured.'
default['gitlab-haproxy']['errors']['503']['subtitle'] = 'Please see our <a href="https://status.gitlab.com">status page</a> for more information.'

default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['listen_addresses'] = node['gitlab-haproxy']['listen_address'].nil? ? ['0.0.0.0', '::'] : [node['gitlab-haproxy']['listen_address']]
default['gitlab-haproxy']['api_address'] = '0.0.0.0'
default['gitlab-haproxy']['maxconn'] = 50000

###############################################################################
#
# HAProxy load balancer configuration, gitlab.com port 443, 80, 22
# This is named frontend, not to be confused with frontends in the HAProxy
#
###############################################################################

default['gitlab-haproxy']['frontend']['blocklist']['uri'] = {}

default['gitlab-haproxy']['frontend']['peers']['servers'] = {}
default['gitlab-haproxy']['frontend']['peers']['port'] = '32768'
default['gitlab-haproxy']['frontend']['peers']['dynamic_lookup'] = false
default['gitlab-haproxy']['frontend']['api']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['api']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['api']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['api']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['api']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['api']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['https_git']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['https_git']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['https_git']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['https_git']['use_verbose_acls'] = false

# These defaults are set so that we can have different defaults for the canary backend.
# They can be removed once https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3465 is complete.
# See also https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/merge_requests/272
default['gitlab-haproxy']['frontend']['canary_https_git']['httpchk_host'] = node['gitlab-haproxy']['frontend']['https_git']['httpchk_host']
default['gitlab-haproxy']['frontend']['canary_https_git']['httpchk_path'] = node['gitlab-haproxy']['frontend']['https_git']['httpchk_path']
default['gitlab-haproxy']['frontend']['canary_https_git']['check_opts'] = node['gitlab-haproxy']['frontend']['https_git']['check_opts']
default['gitlab-haproxy']['frontend']['canary_https_git']['tcp_check_enable'] = node['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable']
default['gitlab-haproxy']['frontend']['canary_https_git']['server_port'] = node['gitlab-haproxy']['frontend']['https_git']['server_port']
default['gitlab-haproxy']['frontend']['canary_https_git']['ssl_verify'] = node['gitlab-haproxy']['frontend']['https_git']['ssl_verify']

default['gitlab-haproxy']['frontend']['https']['extra_bind_port'] = nil
default['gitlab-haproxy']['frontend']['https']['custom_config'] = nil

default['gitlab-haproxy']['kas']['enable'] = false
default['gitlab-haproxy']['kas']['timeout_http_keep_alive'] = '30s'
default['gitlab-haproxy']['kas']['timeout_tunnel'] = '2h'
default['gitlab-haproxy']['kas']['timeout_client'] = '1h'
default['gitlab-haproxy']['kas']['timeout_server'] = '1h'
default['gitlab-haproxy']['kas']['timeout_client_fin'] = '10s'

default['gitlab-haproxy']['frontend']['kas']['bind_extra_options'] = 'alpn h2,http/1.1,spdy/3.1'
default['gitlab-haproxy']['frontend']['kas']['check_opts'] = 'port 8151'
default['gitlab-haproxy']['frontend']['kas']['check_port'] = 8151
default['gitlab-haproxy']['frontend']['kas']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['kas']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['kas']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['kas']['httpchk_path'] = '/liveness'
default['gitlab-haproxy']['frontend']['kas']['port'] = '8150'
default['gitlab-haproxy']['frontend']['kas']['proxy_endpoint'] = '/k8s-proxy'
default['gitlab-haproxy']['frontend']['kas']['proxy_port'] = '8154'
default['gitlab-haproxy']['frontend']['kas']['server_port'] = '8150'
default['gitlab-haproxy']['frontend']['kas']['tcp_check_enable'] = false

default['gitlab-haproxy']['frontend']['canary_kas']['default_weight'] = '100'

default['gitlab-haproxy']['frontend']['ssh']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ssh']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['ssh']['check_opts'] = 'check-ssl port 443 verify none'
default['gitlab-haproxy']['frontend']['ssh']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['ssh']['port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['server_port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['ssl_verify'] = 'ssl verify none'
default['gitlab-haproxy']['frontend']['ssh']['custom_config'] = []
default['gitlab-haproxy']['frontend']['ssh']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['ssh']['send-proxy-v2'] = false
default['gitlab-haproxy']['frontend']['canary_ssh']['send-proxy-v2'] = false

default['gitlab-haproxy']['frontend']['web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['web']['httpchk_path'] = '/-/health'
default['gitlab-haproxy']['frontend']['web']['check_opts'] = 'check-ssl'
default['gitlab-haproxy']['frontend']['web']['tcp_check_enable'] = false
default['gitlab-haproxy']['frontend']['web']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['web']['ssl_verify'] = 'ssl verify none'

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
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['httpchk_host'] = node['gitlab-haproxy']['frontend']['ai_assisted']['httpchk_host']
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['httpchk_path'] = node['gitlab-haproxy']['frontend']['ai_assisted']['httpchk_path']
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['check_opts'] = node['gitlab-haproxy']['frontend']['ai_assisted']['check_opts']
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['tcp_check_enable'] = node['gitlab-haproxy']['frontend']['ai_assisted']['tcp_check_enable']
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['server_port'] = node['gitlab-haproxy']['frontend']['ai_assisted']['server_port']
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['ssl_verify'] = node['gitlab-haproxy']['frontend']['ai_assisted']['ssl_verify']
default['gitlab-haproxy']['frontend']['default_check_opts'] = 'inter 3s fastinter 1s downinter 5s fall 3'

# Asset requests in staging and production are directly sent to Google Cloud Storage public bucket.
# We keep supporting assets in HAProxy for other environments as a fallback measure.
default['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = false
default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_path'] = '/info'
default['gitlab-haproxy']['frontend']['asset_proxy']['httpchk_host'] = 'example.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'example.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['server'] = 'storage.googleapis.com'
default['gitlab-haproxy']['frontend']['asset_proxy']['server_port'] = '443'
default['gitlab-haproxy']['frontend']['asset_proxy']['opts'] = 'check check-ssl inter 2s fastinter 1s downinter 5s fall 3 verify none ssl resolve-prefer ipv4'

default['gitlab-haproxy']['frontend']['web']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['web_k8s']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['api']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['https_git']['default_weight'] = '100'
default['gitlab-haproxy']['frontend']['websockets']['default_weight'] = '100'

default['gitlab-haproxy']['frontend']['canary_web']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_api']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_https_git']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_registry']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['enable'] = true
default['gitlab-haproxy']['frontend']['canary_web']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_api']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_ssh']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_https_git']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_websockets']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_ai_assisted']['default_weight'] = '0'
default['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = []
default['gitlab-haproxy']['frontend']['enforce_cloudflare_origin_pull'] = false

default['gitlab-haproxy']['frontend']['backend']['servers']['default']['api'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['https_git'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['kas'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_kas'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['ssh'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['web'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['web_k8s'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['websockets'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_web'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_websockets'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_api'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_ssh'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_https_git'] = {}
default['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_ai_assisted'] = {}

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['frontend']['backend']['essential'] = %w(api https_git ssh web websockets)

default['gitlab-haproxy']['frontend']['canonical_host'] = 'gitlab.com'

###############################################################################
#
# Pages load balancer configuration, *.gitlab.io port 443 and 80
#
###############################################################################

default['gitlab-haproxy']['pages']['default_weight'] = '100'
default['gitlab-haproxy']['pages']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['pages']['httpchk_path'] = '/-/readiness'
default['gitlab-haproxy']['pages']['http_custom_config'] = nil
default['gitlab-haproxy']['pages']['https_custom_config'] = nil
default['gitlab-haproxy']['pages']['peers']['servers'] = {}
default['gitlab-haproxy']['pages']['peers']['port'] = '32768'
default['gitlab-haproxy']['pages']['peers']['dynamic_lookup'] = false
default['gitlab-haproxy']['pages']['http_backend_listen_port'] = 1080
default['gitlab-haproxy']['pages']['https_backend_listen_port'] = 1443
default['gitlab-haproxy']['pages']['https_proxyv2_backend_listen_port'] = 2443
default['gitlab-haproxy']['pages']['enable_https_proxyv2'] = false
default['gitlab-haproxy']['pages']['enable_domain_rate_limiting'] = false
default['gitlab-haproxy']['pages']['domain_rate_limit_per_second'] = '800'
default['gitlab-haproxy']['pages']['default_check_opts'] = 'inter 3s fastinter 1s downinter 5s fall 3'
default['gitlab-haproxy']['canary_pages']['default_weight'] = '0'
default['gitlab-haproxy']['canary_pages']['http_backend_listen_port'] = node['gitlab-haproxy']['pages']['http_backend_listen_port']
default['gitlab-haproxy']['canary_pages']['https_backend_listen_port'] = node['gitlab-haproxy']['pages']['https_backend_listen_port']
default['gitlab-haproxy']['canary_pages']['https_proxyv2_backend_listen_port'] = node['gitlab-haproxy']['pages']['https_proxyv2_backend_listen_port']

default['gitlab-haproxy']['pages']['backend']['servers']['default']['pages'] = {}
default['gitlab-haproxy']['pages']['backend']['servers']['default']['canary_pages'] = {}

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['pages']['backend']['essential'] = %w(pages)

###############################################################################
#
# Registry load balancer configuration, registry.gitlab.com port 443 and 80
#
###############################################################################

default['gitlab-haproxy']['canary_registry']['default_weight'] = '0'
default['gitlab-haproxy']['registry']['peers']['servers'] = {}
default['gitlab-haproxy']['registry']['peers']['port'] = '32768'
default['gitlab-haproxy']['registry']['peers']['dynamic_lookup'] = false
default['gitlab-haproxy']['registry']['custom_config'] = nil
default['gitlab-haproxy']['registry']['backend_port'] = '5000'
default['gitlab-haproxy']['registry']['ssl_verify'] = nil
default['gitlab-haproxy']['registry']['httpchk_host'] = 'registry.gitlab.com'
default['gitlab-haproxy']['registry']['httpchk_path'] = '/debug/health'
default['gitlab-haproxy']['registry']['tcp_check_enable'] = false
default['gitlab-haproxy']['registry']['default_check_opts'] = 'inter 2s fastinter 1s downinter 5s fall 3 port 5001'
default['gitlab-haproxy']['registry']['default_weight'] = '100'
default['gitlab-haproxy']['registry']['enforce_cloudflare_origin_pull'] = false
default['gitlab-haproxy']['registry']['rate_limit']['enable'] = false
default['gitlab-haproxy']['registry']['rate_limit']['rate_limit_per_10s'] = '4000'

default['gitlab-haproxy']['registry']['backend']['servers']['default']['registry'] = {}
default['gitlab-haproxy']['registry']['backend']['servers']['default']['canary_registry'] = {}

# Essential backends must have at least one server, otherwise the chef-run will fail
default['gitlab-haproxy']['registry']['backend']['essential'] = %w(registry)

default['gitlab-haproxy']['use_canary'] = true

default['gitlab-haproxy']['ci-gateway']['enabled'] = false
default['gitlab-haproxy']['ci-gateway']['listen_port'] = 8989
default['gitlab-haproxy']['ci-gateway']['allowlisted_runner_managers'] = []
default['gitlab-haproxy']['ci-gateway']['allow_artifacts'] = false

# Default period to wait for draining operations to complete when halting the HAProxy service.
default['gitlab-haproxy']['drain-period-seconds'] = 600

# Server state persistence - saves backend server states on reload and restores them
# This preserves health check status across HAProxy reloads
default['gitlab-haproxy']['server_state_persistence']['enable'] = false
default['gitlab-haproxy']['server_state_persistence']['state_file'] = '/etc/haproxy/state/global'
