# rubocop:disable Lint/ImplicitStringConcatenation
control 'haproxy-main-regression-check' do
  impact 1.0
  title 'Tests HAProxy configuration regressions (main flavor, ubuntu 18.04)'
  ref 'production main haproxy.cfg', url: 'https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/merge_requests/335#note_1194904230'
  only_if { command('lsb_release -rs').stdout =~ /18\.04/ }
  desc '
    This control ensures that:
      * The rendered configuration matches production configuration except for listening on port 2222 instead of 22'

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') do
      should include "global
    log /dev/log len 4096 local0
    log /dev/log len 4096 local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats socket ipv4@0.0.0.0:23646 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 50000
    spread-checks 2
    nbproc 1
    nbthread 8
    hard-stop-after 10m
    server-state-file /etc/haproxy/state/global

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    # For more information, see ciphers(1SSL).
    ssl-default-bind-ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!3DES
    ssl-default-bind-options no-tlsv10 no-tlsv11
    # Keep DH params size at 1024 for Java 6 HTTPS clients
    tune.ssl.default-dh-param 1024"
    end
    its('content') do
      should include "defaults
    log global
    option dontlognull
    # Use all backup servers
    # instead of just the first one
    # if other servers are down
    option allbackups
    maxconn 50000
    timeout connect 5000
    timeout check 30000
    timeout client 90s
    timeout server 1h
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/429.http
    errorfile 408 /etc/haproxy/errors/400.http
    errorfile 429 /etc/haproxy/errors/429.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http
    load-server-state-from-file global
    # This configuration makes sure, the backend thinks it's a keep-alive connection, to avoid erratic behaviour
    # But closes the connection to the clients. This is used as a workaround for Cloudflare connection ratelimits.
    option http-pretend-keepalive
    option forceclose"
    end
    its('content') do
      should include 'listen stats
    bind 0.0.0.0:7331
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
    stats auth admin:this-is-a-test-password
    stats admin if TRUE'
    end
    its('content') { should include 'peers frontend-peers' }
    its('content') { should match /peer tk-haproxy-main-ubuntu-18-04-x64-\S+ 0.0.0.0:32768/ }
    its('content') do
      should include 'peer fe-01-lb-gprd example.com:32768
    peer fe-02-lb-gprd example.com:32768'
    end
    its('content') do
      should include 'frontend http
    bind 0.0.0.0:80
    mode http
    option splice-auto

    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    http-request deny if deny-403-ip

    timeout client-fin 5s
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    acl is_www_gitlab_com hdr(host) -i www.gitlab.com

    http-request redirect code 301 location https://gitlab.com%[capture.req.uri] if is_www_gitlab_com
    http-request redirect scheme https code 301'
    end
    its('content') do
      should include 'frontend https
    bind 0.0.0.0:443 ssl crt /etc/haproxy/ssl/gitlab.pem crt /etc/haproxy/ssl/internal.pem crt /etc/haproxy/ssl/canary.pem no-sslv3 verify required ca-file /etc/haproxy/ssl/cf-origin-pull.pem ssl crt /etc/haproxy/ssl/ci-gateway.pem
    # To be used internally within the GCP netwrok, mainly to bypass client certificate verification (if enabled) above
    bind 0.0.0.0:11443 ssl crt /etc/haproxy/ssl/gitlab.pem crt /etc/haproxy/ssl/internal.pem crt /etc/haproxy/ssl/canary.pem crt /etc/haproxy/ssl/ci-gateway.pem no-sslv3
    mode http
    option splice-auto
    timeout client-fin 5s
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    capture request header User-Agent len 64

        acl from_cf src -f /etc/haproxy/cloudflare_ips_v4.lst -f /etc/haproxy/cloudflare_ips_v6.lst
    acl cf_ip_hdr req.hdr(CF-Connecting-IP) -m found
    http-request set-header X-Forwarded-For %[req.hdr(CF-Connecting-IP)] if from_cf cf_ip_hdr
    http-request set-header X-Forwarded-For %[src] if !from_cf || !cf_ip_hdr
    http-request set-header GitLab-Real-IP %[req.hdr(CF-Connecting-IP)] if from_cf cf_ip_hdr
    http-request set-header GitLab-Real-IP %[src] if !from_cf || !cf_ip_hdr
    http-request del-header Client-Ip
    # This sets the `src` variable to the CF-Connecting-IP when the request comes from Cloudflare
    http-request set-src hdr(CF-Connecting-IP) if from_cf cf_ip_hdr
    stick-table type ip size 1m expire 5m store gpc0,http_req_rate(1m) peers frontend-peers
    # We cannot use tcp-request connection here, as it sees the unmasked src. This would cause us to track
    # incoming connections from Cloudflare, rather than originating clients.
    # Also using http-request track fixes issues with rate-limits not being accurately measured.
    http-request track-sc1 src

    # https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xhtml
    acl is_ipv6 src 2000::/3
    acl is_www_gitlab_com hdr(host) -i www.gitlab.com
    acl is_socket_upg hdr(Upgrade) -i WebSocket
    acl is_socket_path path_end -i .ws
    acl is_gitlab_com_api path_beg -i /api/
    acl is_gitlab_com_ci_artifacts_api path_reg -i ^\/api\/v\d\/jobs\/\d+\/artifacts($|\/)
    acl is_gitlab_com_internal_api path_reg -i ^\/api\/v\d\/internal\/pages($|\/)
    acl is_ancient_ci_runner path_beg -i /ci/api/
    acl is_https_git path_reg -i ^\/(?!help)[^\/]+\/((?!artifacts|browse|file|tree|blob|blame|commits|raw|find_file|files|graphs|logs_tree|refs|wikis|new|create|edit|update|preview|badges)[^\/]+\/)*[^\/]+\.git($|\/)
    acl is_gitlab_com_jwt_auth path -i /jwt/auth
    acl is_legacy_ci_runner hdr_reg(User-Agent) -i gitlab-ci-multi-runner\ 1\.
    acl has_multiple_slash path_reg /{2,}
    acl is_canary req.cook(gitlab_canary) -m str -i true
    acl canary_disabled req.cook(gitlab_canary) -m str -i false
    acl is_canary_host hdr_beg(host) -i canary
    acl no_be_srvs_canary_web nbsrv(canary_web) lt 1
    acl no_be_srvs_canary_https_git nbsrv(canary_https_git) lt 1
    acl no_be_srvs_canary_api nbsrv(canary_api) lt 1
    acl is_canary_path path_beg -f /etc/haproxy/canary-request-paths.lst
    acl is_asset_path path_beg /assets/
    acl whitelist_internal src -f /etc/haproxy/whitelist-internal.lst
    acl whitelist_api src -f /etc/haproxy/whitelist-api.lst
    acl api_rate_limit_whitelist src 1.2.3.4 5.6.7.8
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/packages/
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/projects/[^/]+/packages(/|$)
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/groups?/[^/]+/-/packages(/|$)
    acl is_gitlab_com_go_get query -m str "go-get=1"
    acl is_gitlab_com_go_get query -m beg "go-get=1&"
    acl is_gitlab_com_go_get query -m sub "&go-get=1&"
    acl is_gitlab_com_go_get query -m end "&go-get=1"

    http-request set-var(txn.host) hdr(Host)
    http-request redirect code 308 location https://gitlab.com%[capture.req.uri] if is_www_gitlab_com
    http-request redirect code 308 location https://%[hdr(host)]%[url,regsub(/+,/,g)] if has_multiple_slash
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-SSL %[ssl_fc]
    http-request deny deny_status 400 if is_legacy_ci_runner
    http-request deny deny_status 400 if is_ancient_ci_runner

    # Prevent users from setting bypass header
    http-request set-header X-GitLab-RateLimit-Bypass 0

    # IP whitelists
    http-request set-header X-GitLab-RateLimit-Bypass 1 if whitelist_internal
    http-request set-header X-GitLab-RateLimit-Bypass 1 if whitelist_api
    http-request set-header X-GitLab-RateLimit-Bypass 1 if api_rate_limit_whitelist
    # Git HTTP https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/691
    http-request set-header X-GitLab-RateLimit-Bypass 1 if is_https_git
    # JWT auth https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/692
    http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_jwt_auth
    # Package registries https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/710
    http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_package_registry
    # Package registries https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/710
    http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_go_get'
    end
    its('content') { should match /http-response set-header GitLab-LB tk-haproxy-main-ubuntu-18-04-x64-\S+/ }
    its('content') do
      should include 'http-response set-header GitLab-SV %s

    http-request allow if whitelist_internal

    acl require_captcha src -f /etc/haproxy/recaptcha/require-captcha.lst
    http-request set-header X-GitLab-Show-Login-Captcha 1 if require_captcha

    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    http-request deny if deny-403-ip

    acl blacklist-uri path_beg -i -f /etc/haproxy/blacklist-uris.lst
    http-request deny if blacklist-uri

    # Overridden to test injection #####
    # override for https frontend
    ####################################

    acl no_be_srvs_asset_proxy nbsrv(asset_proxy) lt 1
    ###############################################################
    # Asset routing, all requests for /assets/ are routes to the
    # asset object-storage bucket
    # There is a basic health check for a file named /info, in the bucket
    # if it doesn\'t exist, asset requests will go to the front-end workers
    use_backend asset_proxy if is_asset_path !no_be_srvs_asset_proxy

    ###############################################################
    # API routing rules for whitelisted hosts that
    # bypass rate limiting
    use_backend api if is_gitlab_com_ci_artifacts_api
    use_backend api if is_gitlab_com_api api_rate_limit_whitelist

    ## ipv6 routing rules for canary API
    use_backend main_api if is_gitlab_com_api is_ipv6 canary_disabled
    use_backend api if is_gitlab_com_api is_ipv6 no_be_srvs_canary_api
    use_backend canary_api if is_gitlab_com_api is_ipv6 is_canary
    use_backend canary_api if is_gitlab_com_api is_ipv6 is_canary_path !canary_disabled
    use_backend api if is_gitlab_com_api is_ipv6

    use_backend api if is_gitlab_com_internal_api
    use_backend api if is_gitlab_com_api whitelist_internal
    use_backend api if is_gitlab_com_api whitelist_api
    # API routing rules for rate limiting, canary
    # routing is handled in the api_rate_limit frontend
    # This backend is a proxy for the api_rate_limit frontend
    use_backend api_rate_limit if is_gitlab_com_api
    ###############################################################

    ###############################################################
    # HTTPS GIT routing rules
    # Note we do not route to the https git backend based on request paths
    # see https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1182
    # If it is an https git request and there are no healthy canary
    # servers, route request to the https_git backend
    use_backend https_git if is_https_git no_be_srvs_canary_https_git
    # Use the canary backend if the cookie gitlab_canary=true is set or if the request
    # is sent to canary.gitlab.com
    use_backend canary_https_git if is_https_git is_canary
    use_backend canary_https_git if is_https_git is_canary_host
    # Finally, if no canary rules match, route requests to the normal
    # https_git backend
    use_backend https_git if is_https_git
    ###############################################################

    ###############################################################
    # Websockets routing rules
    use_backend websockets if is_socket_upg or is_socket_path
    ###############################################################

    ###############################################################
    # Web routing rules, if we have gotten this far we use the default
    # web or canary_web backend
    # If the canary cookie is set to false, use the main web backend
    use_backend main_web if canary_disabled
    # If there are no healthy canary servers default to the web backend
    use_backend web if no_be_srvs_canary_web
    # Use the canary for internal request paths like /gitlab-com/, unless
    # the cookie gitlab_canary=false is set
    use_backend canary_web if is_canary_path !canary_disabled
    # Use the canary backend if the cookie gitlab_canary=true or if the
    # request is sent to canary.gitlab.com
    use_backend canary_web if is_canary or is_canary_host
    # Finally, if no other rules match, send the request to the web backend
    default_backend web'
    end
    its('content') do
      should include 'frontend kas
    bind 0.0.0.0:8150 ssl crt /etc/haproxy/ssl/kas.pem npn spdy/3.1,http/1.1
    mode http
    option splice-auto
    option http-keep-alive
    no option http-pretend-keepalive

    acl from_cf src -f /etc/haproxy/cloudflare_ips_v4.lst -f /etc/haproxy/cloudflare_ips_v6.lst
    # This sets the `src` variable to the CF-Connecting-IP when the request comes from Cloudflare
    tcp-request connection expect-proxy layer4 if from_cf
    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    tcp-request content reject if deny-403-ip

    timeout http-request 10s
    timeout http-keep-alive 30s
    timeout client 1h
    timeout client-fin 5s

    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    stick-table type ip size 1m expire 5m store gpc0,conn_rate(1m) peers frontend-peers

    # Overridden to test injection #####
    # override for kas frontend
    ####################################
    acl no_be_srvs_canary_kas nbsrv(canary_kas) lt 1
    acl is_canary req.cook(gitlab_canary) -m str -i true
    acl canary_disabled req.cook(gitlab_canary) -m str -i false

    ###############################################################
    # KAS routing rules
    # If the canary cookie is set to false, use the main kas backend
    use_backend kas_k8s_proxy if { path_beg /k8s-proxy } canary_disabled
    use_backend kas if canary_disabled
    # If there are no healthy canary servers default to the kas backend
    use_backend kas_k8s_proxy if { path_beg /k8s-proxy } no_be_srvs_canary_kas
    use_backend kas if no_be_srvs_canary_kas
    # Use the canary backend if the cookie gitlab_canary=true
    use_backend canary_kas_k8s_proxy if is_canary { path_beg /k8s-proxy }
    use_backend canary_kas if is_canary
    # Finally, if no canary rules match, route requests to the normal
    # kas backends
    use_backend kas_k8s_proxy if { path_beg /k8s-proxy }
    use_backend kas'
    end
    its('content') do
      should include 'frontend ssh
    bind 0.0.0.0:2222
    mode tcp
    option splice-auto

    acl from_cf src -f /etc/haproxy/cloudflare_ips_v4.lst -f /etc/haproxy/cloudflare_ips_v6.lst
    # This sets the `src` variable to the CF-Connecting-IP when the request comes from Cloudflare
    tcp-request connection expect-proxy layer4 if from_cf
    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    tcp-request content reject if deny-403-ip

    timeout client-fin 5s
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tw/%Tc/%Tt\ %B\ %U\ %ts\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq
    stick-table type ip size 1m expire 5m store gpc0,conn_rate(1m) peers frontend-peers

    # Overridden to test injection #####
    # override for ssh frontend
    ####################################

    use_backend ssh'
    end
    its('content') do
      should include 'frontend check_http
    bind 0.0.0.0:8001
    mode http
    option splice-auto
    acl no_be_srvs_web nbsrv(web) lt 1
    monitor-uri /-/available-http
    monitor fail if no_be_srvs_web'
    end
    its('content') do
      should include 'frontend check_https
    bind 0.0.0.0:8002
    mode http
    option splice-auto
    acl no_be_srvs_web nbsrv(web) lt 1
    acl no_be_srvs_api nbsrv(api) lt 1
    monitor-uri /-/available-https
    monitor fail if no_be_srvs_web || no_be_srvs_api'
    end
    its('content') do
      should include 'frontend check_ssh
    bind 0.0.0.0:8003
    mode http
    option splice-auto
    acl no_be_srvs_ssh nbsrv(ssh) lt 1
    monitor-uri /-/available-ssh
    monitor fail if no_be_srvs_ssh'
    end
    its('content') do
      should include 'frontend api_rate_limit
    bind 127.0.0.1:4444 accept-proxy
    mode http
    option splice-auto
    stick-table type ip size 1m expire 5m store gpc0,http_req_rate(1m) peers frontend-peers
    http-request track-sc1 src
    acl is_rate_abuse src_http_req_rate gt 2000
    http-request set-var(txn.src_http_req_rate) src_http_req_rate
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/packages/
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/projects/[^/]+/packages(/|$)
    acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/groups?/[^/]+/-/packages(/|$)
    acl is_package_registry_rate_abuse src_http_req_rate gt 7000

    acl has_ratelimit_headers res.hdr(RateLimit-Limit) -m found

    http-response set-header RateLimit-Observed %[src_http_req_rate] if !has_ratelimit_headers
    http-response set-header RateLimit-Remaining %[int(2000),sub(txn.src_http_req_rate)] if !has_ratelimit_headers
    http-response set-header RateLimit-Reset %[date(60)] if !has_ratelimit_headers
    http-response set-header RateLimit-ResetTime %[date(60),http_date] if !has_ratelimit_headers
    # Override these headers for package registry requests
    http-response set-header RateLimit-Remaining %[int(7000),sub(txn.src_http_req_rate)] if is_gitlab_com_package_registry !has_ratelimit_headers
    http-response set-header RateLimit-Limit 7000 if is_gitlab_com_package_registry !has_ratelimit_headers
    http-response set-header RateLimit-Limit 2000 if !is_gitlab_com_package_registry !has_ratelimit_headers
    use_backend 429_slow_down if is_gitlab_com_package_registry is_package_registry_rate_abuse
    # No need for any canary handling; paths that match the package registries do not have canary-type identifiers
    use_backend api if is_gitlab_com_package_registry
    use_backend 429_slow_down if is_rate_abuse

    acl no_be_srvs_canary_api nbsrv(canary_api) lt 1
    acl is_canary_path path_beg -f /etc/haproxy/canary-request-paths.lst
    acl is_canary_host hdr_beg(host) -i canary
    acl is_canary req.cook(gitlab_canary) -m str -i true
    acl canary_disabled req.cook(gitlab_canary) -m str -i false



    ###############################################################
    # API routing rules
    # If the canary cookie is set to false, use the main api backend
    use_backend main_api if canary_disabled
    # If there are no healthy canary servers default to the api backend
    use_backend api if no_be_srvs_canary_api
    # Use the canary for internal request paths like /gitlab-com/, unless
    # the cookie gitlab_canary=false is set
    use_backend canary_api if is_canary_path !canary_disabled
    # Use the canary backend if the cookie gitlab_canary=true or if the
    # request is sent to canary.gitlab.com
    use_backend canary_api if is_canary or is_canary_host
    # Finally, if no canary rules match, route requests to the normal
    # api backend
    default_backend api'
    end
    its('content') do
      should include 'frontend https_git_ci_gateway
    bind 0.0.0.0:8989 ssl crt /etc/haproxy/ssl/ci-gateway.pem no-sslv3
    mode http
    option splice-auto
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    capture request header User-Agent len 64

    acl is_runner_manager src 10.0.0.0/8
    acl is_api_jobs_request path_reg -i ^\/api\/v\d\/jobs\/request$
    acl is_api_jobs_id path_reg -i ^\/api\/v\d\/jobs\/\d+$
    acl is_api_jobs_id_trace path_reg -i ^\/api\/v\d\/jobs\/\d+\/trace$
    acl is_patch_method method PATCH

    acl is_https_git path_reg -i ^\/(?!help)[^\/]+\/((?!artifacts|browse|file|tree|blob|blame|commits|raw|find_file|files|graphs|logs_tree|refs|wikis|new|create|edit|update|preview|badges)[^\/]+\/)*[^\/]+\.git($|\/)
    acl is_git_method method GET POST

    acl is_git_legacy_initial_request path_reg -i ^\/[^\/]+(\/[^\/]+)+\/info\/refs$
    acl is_git_new_initial_request path_reg -i ^\/[^\/]+(\/[^\/]+)+.git\/info\/refs$

    # Prevent users from setting bypass header
    http-request set-header X-GitLab-RateLimit-Bypass 0

    # Set the canonical host as Host header so that ci-gateway
    # is transparent for GitLab backends
    http-request set-header Host gitlab.com

    ###############################################################
    # Redirect git requests missing .git suffix in the repo url
    use_backend ci_gateway_git_repo_redirection if is_git_legacy_initial_request !is_git_new_initial_request is_git_method
    ###############################################################

    ###############################################################
    # HTTPS git routing
    http-request set-header X-GitLab-RateLimit-Bypass 1 if is_https_git is_git_method
    use_backend https_git if is_https_git is_git_method
    ###############################################################

    ###############################################################
    # Limited API routing
    use_backend api if is_runner_manager is_api_jobs_request METH_POST
    use_backend api if is_runner_manager is_api_jobs_id METH_PUT
    use_backend api if is_runner_manager is_api_jobs_id_trace is_patch_method
    ###############################################################

    ###############################################################
    # Redirect to GitLab public entrypoint otherwise
    default_backend ci_gateway_catch_all'
    end
    its('content') do
      should include 'backend asset_proxy
    mode http
    option httpchk GET /info HTTP/1.1\r\nHost:\ gitlab-gprd-assets.storage.googleapis.com
    http-request set-header Host gitlab-gprd-assets.storage.googleapis.com
    server asset-bucket storage.googleapis.com:443 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 ssl verify none'
    end
    its('content') do
      should include 'backend api
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/k8s/api/-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server api-gke-us-east1-b 10.221.13.25:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none
    server api-gke-us-east1-c 10.221.14.23:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none backup
    server api-gke-us-east1-d 10.221.15.31:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none backup
    server gke-cny-api 10.216.8.44:443 weight 5 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none'
    end
    its('content') do
      should include 'backend main_api
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/k8s/api/-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server api-gke-us-east1-b 10.221.13.25:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none
    server api-gke-us-east1-c 10.221.14.23:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none backup
    server api-gke-us-east1-d 10.221.15.31:443 weight 100 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none backup'
    end
    its('content') do
      should include 'backend api_rate_limit
    option splice-auto
    mode http
    server localhost 127.0.0.1:4444 send-proxy'
    end
    its('content') do
      should include 'backend https_git
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server git-https-gke-us-east1-b 10.221.13.9:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3 ''
    server git-https-gke-us-east1-c 10.221.14.17:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup
    server git-https-gke-us-east1-d 10.221.15.3:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup
    server gke-cny-git-https 10.216.8.10:8181 weight 5 check port 8181 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend web
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server web-gke-us-east1-b 10.221.13.65:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3 ''
    server web-gke-us-east1-c 10.221.14.55:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup
    server web-gke-us-east1-d 10.221.15.66:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup
    server gke-cny-web 10.216.8.87:8181 weight 3 check port 8181 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend main_web
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server web-gke-us-east1-b 10.221.13.65:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3 ''
    server web-gke-us-east1-c 10.221.14.55:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup
    server web-gke-us-east1-d 10.221.15.66:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  backup'
    end
    its('content') do
      should include 'backend canary_web
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    acl is_canary_host hdr_beg(host) -i canary
    http-response set-header X-Robots-Tag noindex if { var(txn.host) -m beg canary }
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server gke-cny-web 10.216.8.87:8181 check port 8181 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend canary_https_git
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option tcp-check
    server gke-cny-git-https 10.216.8.10:8181 check port 8181 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend canary_api
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option httpchk GET /-/k8s/api/-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server gke-cny-api 10.216.8.44:443 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none'
    end
    its('content') do
      should include 'backend kas
    mode http
    balance roundrobin
    option splice-auto
    option http-keep-alive
    no option http-pretend-keepalive
    timeout http-keep-alive 30s
    timeout server 1h
    timeout tunnel 2h
    option httpchk GET /liveness HTTP/1.1\r\nHost:\ kas.gitlab.com
    server kas-gke 10.216.8.102:8150 weight 100 check port 8151 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend kas_k8s_proxy
    mode http
    balance roundrobin
    option splice-auto
    option http-keep-alive
    no option http-pretend-keepalive
    timeout http-keep-alive 30s
    timeout server 1h
    timeout tunnel 2h
    option httpchk GET /liveness HTTP/1.1\r\nHost:\ kas.gitlab.com
    server kas-gke 10.216.8.102:8154 weight 100 check port 8151 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend canary_kas
    mode http
    balance roundrobin
    option splice-auto
    option http-keep-alive
    no option http-pretend-keepalive
    timeout http-keep-alive 30s
    timeout server 1h
    timeout tunnel 2h
    option httpchk GET /liveness HTTP/1.1\r\nHost:\ kas.gitlab.com
    server gke-cny-web 10.216.8.85:8150 weight 5 check port 8151 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend canary_kas_k8s_proxy
    mode http
    balance roundrobin
    option splice-auto
    option http-keep-alive
    no option http-pretend-keepalive
    timeout http-keep-alive 30s
    timeout server 1h
    timeout tunnel 2h
    option httpchk GET /liveness HTTP/1.1\r\nHost:\ kas.gitlab.com
    server gke-cny-web 10.216.8.85:8154 weight 5 check port 8151 inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend ssh
    mode tcp
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    timeout server 2h
    option tcp-check
    server shell-gke-us-east1-b 10.221.13.40:2222 weight 100 check  inter 3s fastinter 1s downinter 5s fall 3 send-proxy-v2
    server shell-gke-us-east1-c 10.221.14.5:2222 weight 100 check  inter 3s fastinter 1s downinter 5s fall 3 backup send-proxy-v2
    server shell-gke-us-east1-d 10.221.15.5:2222 weight 100 check  inter 3s fastinter 1s downinter 5s fall 3 backup send-proxy-v2
    server gke-cny-ssh 10.216.8.61:2222 weight 5 check  inter 3s fastinter 1s downinter 5s fall 3 send-proxy-v2'
    end
    its('content') do
      should include 'backend websockets
    mode http
    balance roundrobin
    option splice-auto
    option http-server-close
    timeout tunnel 8s
    cookie _gitlab_session prefix nocache
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server ws-gke-us-east1-b 10.221.13.19:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  cookie ws-gke-us-east1-b
    server ws-gke-us-east1-c 10.221.14.26:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  cookie ws-gke-us-east1-c backup
    server ws-gke-us-east1-d 10.221.15.37:8181 weight 100 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  cookie ws-gke-us-east1-d backup
    server gke-cny-ws 10.216.8.15:8181 weight 5 check port 8181 inter 3s fastinter 1s downinter 5s fall 3  cookie gke-cny-ws'
    end
    its('content') do
      should include 'backend 429_slow_down
    mode http
    timeout tarpit 2s
    errorfile 429 /etc/haproxy/errors/429.http
    http-request tarpit deny_status 429'
    end
    its('content') do
      should include 'backend ci_gateway_catch_all
    mode http
    # Code 307 is important as it hints to the client to redirect keeping the original method,
    # necessary for requests like POST /api/v4/jobs/:id/artifacts which won\'t be captured by the frontend.
    http-request redirect code 307 location https://gitlab.com%[capture.req.uri]'
    end
    its('content') do
      should include 'backend ci_gateway_git_repo_redirection
    mode http
    http-request set-var(req.repo_path) path,regsub(\/info\/refs$,.git/info/refs)
    http-request redirect code 307 location %[var(req.repo_path)]?%[query]'
    end
  end
end
