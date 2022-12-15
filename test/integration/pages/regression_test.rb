
control 'haproxy-pages-regression-check' do
  impact 1.0
  title 'Tests HAProxy configuration regressions (pages flavour, ubuntu 18.04)'
  ref 'production pages haproxy.cfg', url: 'https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/merge_requests/335#note_1194915753'
  only_if { command('lsb_release -rs').stdout =~ /18\.04/ }
  desc '
    This control ensures that:
      * The rendered configuration matches production configuration'

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
    maxconn 40000 # raising in the defaults without raising global makes no sense (!!)
    nbproc 1
    nbthread 8
    hard-stop-after 10m
    server-state-file /etc/haproxy/state/global

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    # For more information, see ciphers(1SSL).
    ssl-default-bind-ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4
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
    maxconn 40000 # raising in the defaults without raising global makes no sense (!!)
    timeout connect 5000
    timeout check 30000
    timeout client 90s
    timeout server 1h
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/429.http
    errorfile 408 /etc/haproxy/errors/400.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http
    load-server-state-from-file global"
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
    its('content') { should include 'peers pages-peers' }
    its('content') { should match /peer tk-haproxy-pages-ubuntu-18-04-x64-\S+ 0.0.0.0:32768/ }

    its('content') do
      should include 'peer fe-pages-01-lb-gprd example.com:32768
    peer fe-pages-02-lb-gprd example.com:32768'
    end
    its('content') do
      should include 'frontend pages_http
    bind 0.0.0.0:80
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
    acl deny-403-domain req.hdr(host) -i -f /etc/haproxy/front-end-security/deny-403-pages-domains.lst
    use_backend deny_http if deny-403-domain

    acl mark_seen sc0_inc_gpc0 gt 0
    acl domain_deny sc0_conn_rate gt 600
    stick-table type string len 128 size 1m expire 10s store gpc0,conn_rate(1s) peers pages-peers
    tcp-request content track-sc0 hdr(host)
    use_backend deny_http if domain_deny mark_seen
    capture request header Host len 40
    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %U\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r
    acl doc_gitlab_com hdr_beg(host) -i doc.gitlab.com
    http-request redirect location https://docs.gitlab.com%[path] if doc_gitlab_com
    use_backend pages_http'
    end
    its('content') do
      should include 'frontend pages_https
    bind 0.0.0.0:443
    mode tcp
    option splice-auto

    tcp-request inspect-delay 5s
    acl deny-403-ip src -f /etc/haproxy/front-end-security/deny-403-ips.lst
    use_backend deny_https if deny-403-ip
    acl deny-403-domain req_ssl_sni -i -f /etc/haproxy/front-end-security/deny-403-pages-domains.lst
    use_backend deny_https if deny-403-domain
    acl mark_seen sc0_inc_gpc0 gt 0
    acl domain_deny sc0_conn_rate gt 600

    stick-table type string len 128 size 1m expire 10s store gpc0,conn_rate(1s) peers pages-peers
    tcp-request content track-sc0 req_ssl_sni
    use_backend deny_https if mark_seen domain_deny

    log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tw/%Tc/%Tt\ %B\ %U\ %ts\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq
    use_backend pages_https'
    end
    its('content') do
      should include 'frontend check_http
    bind 0.0.0.0:8001
    mode http
    option splice-auto
    acl no_be_srvs_http nbsrv(pages_http) lt 1
    monitor-uri /-/available-http
    monitor fail if no_be_srvs_http'
    end
    its('content') do
      should include 'frontend check_https
    bind 0.0.0.0:8002
    mode http
    option splice-auto
    acl no_be_srvs_https nbsrv(pages_https) lt 1
    monitor-uri /-/available-https
    monitor fail if no_be_srvs_https'
    end
    its('content') do
      should include 'backend pages_http
    mode http
    balance roundrobin
    option splice-auto
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server pages-us-east1-b 10.221.13.5:80 weight 100 check inter 3s fastinter 1s downinter 5s fall 3
    server pages-us-east1-c 10.221.14.130:80 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 backup
    server pages-us-east1-d 10.221.15.6:80 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 backup
    server gke-cny-pages 10.216.8.25:80 weight 5 check inter 3s fastinter 1s downinter 5s fall 3'
    end
    its('content') do
      should include 'backend pages_https
    mode tcp
    option splice-auto
    balance roundrobin
    option httpchk GET /-/readiness HTTP/1.1\r\nHost:\ gitlab.com
    server pages-us-east1-b-proxyv2 10.221.13.5:443 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 port 80 send-proxy-v2
    server pages-us-east1-c-proxyv2 10.221.14.130:443 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 port 80 backup send-proxy-v2
    server pages-us-east1-d-proxyv2 10.221.15.6:443 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 port 80 backup send-proxy-v2
    server gke-cny-pages-proxyv2 10.216.8.25:443 weight 5 check inter 3s fastinter 1s downinter 5s fall 3 port 80 send-proxy-v2'
    end
    its('content') do
      should include 'backend deny_https
    mode tcp
    tcp-request content reject'
    end
    its('content') do
      should include 'backend deny_http
    mode http
    http-request deny'
    end
  end
end
