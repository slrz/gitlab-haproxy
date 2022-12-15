
control 'haproxy-registry-regression-check' do
  impact 1.0
  title 'Tests HAProxy configuration regressions (registry flavour, ubuntu 18.04)'
  ref 'production registry haproxy.cfg', url: 'https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/merge_requests/335#note_1194908460'
  only_if { command('lsb_release -rs').stdout =~ /18\.04/ }
  desc '
    This control ensures that:
      * The rendered configuration matches production configuration'

  describe file('/etc/haproxy/haproxy.cfg') do
    its('content') do
      should include 'global
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
    nbthread 4
    hard-stop-after 10m
    server-state-file /etc/haproxy/state/global
    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    # For more information, see ciphers(1SSL).
    ssl-default-bind-ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:!TLS_RSA_WITH_AES_256_GCM_SHA384:!TLS_RSA_WITH_AES_256_CBC_SHA:!TLS_RSA_WITH_AES_256_CBC_SHA256:!TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:!TLS_RSA_WITH_AES_128_GCM_SHA256:!TLS_RSA_WITH_AES_128_CBC_SHA:!TLS_RSA_WITH_AES_128_CBC_SHA256:!TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!3DES
    # Keep DH params size at 1024 for Java 6 HTTPS clients
    tune.ssl.default-dh-param 1024'
    end
    its('content') do
      should include 'defaults
    log global
    maxconn 50000
    option dontlognull
    # Use all backup servers
    # instead of just the first one
    # if other servers are down
    option allbackups
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
    load-server-state-from-file global'
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
    its('content') { should include 'peers registry-peers' }
    its('content') { should match /peer tk-haproxy-registry-ubuntu-18-04-x64-\S+ 0.0.0.0:32768/ }

    its('content') do
      should include 'peer fe-registry-01-lb-gprd example.com:32768
    peer fe-registry-02-lb-gprd example.com:32768'
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
    http-request redirect scheme https code 301'
    end
    its('content') do
      should include 'frontend https
    bind 0.0.0.0:443 ssl crt /etc/haproxy/ssl/registry.pem crt /etc/haproxy/ssl/internal.pem no-sslv3
    mode http
    option splice-auto

    acl from_cf src -f /etc/haproxy/cloudflare_ips_v4.lst -f /etc/haproxy/cloudflare_ips_v6.lst
    acl cf_ip_hdr req.hdr(CF-Connecting-IP) -m found
    http-request set-header X-Forwarded-For %[req.hdr(CF-Connecting-IP)] if from_cf cf_ip_hdr
    http-request set-header X-Forwarded-For %[src] if !from_cf || !cf_ip_hdr
    http-request set-header GitLab-Real-IP %[req.hdr(CF-Connecting-IP)] if from_cf cf_ip_hdr
    http-request set-header GitLab-Real-IP %[src] if !from_cf || !cf_ip_hdr
    http-request del-header Client-Ip

    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    http-request deny if deny-403-ip

    timeout client-fin 5s
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    capture request header User-Agent len 64

    stick-table type ip size 1m expire 5m store gpc0,conn_rate(1m) peers registry-peers
    tcp-request connection track-sc1 src

    acl has_multiple_slash path_reg /{2,}

    http-request redirect code 308 location https://%[hdr(host)]%[url,regsub(/+,/,g)] if has_multiple_slash
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-SSL %[ssl_fc]

    acl is_canary_path path_beg -f /etc/haproxy/canary-request-paths.lst
    acl is_canary_host hdr_beg(host) -i canary
    acl is_canary req.cook(gitlab_canary) -m str -i true
    acl canary_disabled req.cook(gitlab_canary) -m str -i false
    acl no_be_srvs_canary_registry nbsrv(canary_registry) lt 1

    # Overridden to test injection #####
    # override for registry frontend
    ####################################

    ###############################################################
    # Registry routing
    # If there are no healthy canary servers default to the web backend
    use_backend registry if no_be_srvs_canary_registry
    # Use the canary for internal request paths like /gitlab-com/
    use_backend canary_registry if is_canary_path !canary_disabled
    # Use the canary backend if the cookie gitlab_canary=true or if the
    # request is sent to canary.gitlab.com
    use_backend canary_registry if is_canary or is_canary_host
    # Finally, if no other rules match, send the request to the registry backend
    default_backend registry'
    end
    its('content') do
      should include 'frontend check_http
    bind 0.0.0.0:8001
    mode http
    option splice-auto
    acl no_be_srvs_reg nbsrv(registry) lt 1
    monitor-uri /-/available-http
    monitor fail if no_be_srvs_reg'
    end
    its('content') do
      should include 'frontend check_https
    bind 0.0.0.0:8002
    mode http
    option splice-auto
    acl no_be_srvs_reg nbsrv(registry) lt 1
    monitor-uri /-/available-https
    monitor fail if no_be_srvs_reg'
    end
    its('content') do
      should include 'backend registry
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option tcp-check
    server registry-us-east1-b 10.221.13.41:5000 weight 100 check inter 2s fastinter 1s downinter 5s fall 3 port 5001
    server registry-us-east1-c 10.221.14.3:5000 weight 100 check inter 2s fastinter 1s downinter 5s fall 3 port 5001 backup
    server registry-us-east1-d 10.221.15.4:5000 weight 100 check inter 2s fastinter 1s downinter 5s fall 3 port 5001 backup
    server gke-cny-registry 10.216.8.18:5000 weight 10 check inter 2s fastinter 1s downinter 5s fall 3 port 5001'
    end
    its('content') do
      should include 'backend canary_registry
    mode http
    balance roundrobin
    option splice-auto
    timeout server-fin 5s
    option tcp-check
    server gke-cny-registry 10.216.8.18:5000 check inter 2s fastinter 1s downinter 5s fall 3 port 5001'
    end
  end
end
