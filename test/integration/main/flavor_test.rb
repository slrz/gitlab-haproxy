control 'haproxy-main-flavor-checks' do
  impact 1.0
  title 'HAProxy configuration tests for the main flavor'
  desc '
    This control ensures that:
      • specific configurations for the main flavor are present in the HAProxy configuration'

  [
    7331, # stats
    80, # http
    443, # https
    2222, # ssh. remapped because kitchen listens on port 22. In production this port would be 22.
    8001, # check_http
    8002, # check_https
    8003, # check_ssh
  ].each do |nr|
    describe port(nr) do
      its('processes') { should eq ['haproxy'] }
      its('addresses') { should eq ['0.0.0.0'] }
      its('protocols') { should eq ['tcp'] }
    end
  end

  # Tests Gitlab::TemplateHelpers::merge_settings and its property merging
  describe file('/etc/haproxy/haproxy.cfg') do
    # global section
    its('content') do
      should include 'timeout server 90s' # default in template
    end
    its('content') do
      should include 'no-memory-trimming'
    end
    its('content') do
      should include 'ssl-mode-async'
    end
    its('content') do
      should include 'tune.ssl.lifetime 900'
    end
    its('content') do
      should include 'spread-checks 4'
    end
    its('content') do
      should include 'hard-stop-after 30m'
    end
    # defaults section
    its('content') do
      should include 'retry-on conn-failure'
    end
    its('content') do
      should include 'option redispatch'
    end
    its('content') do
      should include 'option splice-auto'
    end
    its('content') do
      should include 'option tcpka'
    end
    its('content') do
      should include 'option tcp-smart-connect'
    end

    # override for main_api backends
    its('content') do
      should include 'timeout server 10m'
    end

    # override for https_git backends
    its('content') do
      should include 'timeout server 1h'
    end

    # override for kas backends
    its('content') do
      should include('timeout tunnel 2h').exactly(6).times
      should include('timeout client 1h # KAS specific tuning for SPDY').exactly(:once)
      should include('timeout server 1h # KAS specific tuning for SPDY').exactly(6).times # kas, kas_grpc, kas_k8s_proxy, canary_kas, canary_kas_grpc, canary_kas_k8s_proxy
    end
  end

  # General config related flavor differences
  describe file('/etc/haproxy/haproxy.cfg') do
    # ssh backend should use the TCP logstring
    its('content') do
      should include 'log-format %ci:%cp\ %fi:%fp\ %bi:%bp\ %si:%sp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tw/%Tc/%Tt\ %B\ %U\ %ts\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq'
    end

    # Peer section is being included
    its('content') do
      should include('peers main-peers
  bind 0.0.0.0:32769',
                     'server haproxy-main-02-lb-gprd 34.74.226.1:32769')
    end

    # Validates that local peer detection works, and no IP:port pair is inserted for it
    its('content') { should match /32769\n  server tk-haproxy-main-ubuntu-\d\d-\d\d-x64-.+? \n/ }

    # backend availability. Tests Gitlab::TemplateHelpers::select_backends
    %w(asset_proxy api main_api ai_assisted https_git web main_web canary_web canary_https_git canary_api kas kas_grpc kas_k8s_proxy canary_kas canary_kas_grpc canary_kas_k8s_proxy ssh websockets ci_gateway_catch_all ci_gateway_git_repo_redirection).each do |backend|
      its('content') do
        should include "backend #{backend}"
      end
    end

    # frontend availability. Tests Gitlab::TemplateHelpers::select_frontends
    %w(http https kas ssh https_git_ci_gateway).each do |backend|
      its('content') do
        should include "frontend #{backend}"
      end
    end

    its('content') do
      should include 'acl is_http2 fc_http_major eq 2'
      should include 'use_backend canary_kas_grpc if is_http2'
      should include 'use_backend kas_grpc if is_http2'
      should include "use_backend kas\n"
    end

    # Tests Gitlab::TemplateHelpers::merge_check_frontends and its property merging
    its('content') do
      should include 'frontend check_https
  bind 0.0.0.0:8002 tfo
  bind :::8002 tfo
  mode http',
                     'monitor-uri /-/available-https
  monitor fail if !backend_available_web !backend_available_api'
    end

    # Verifies correct template handling in frontend definition
    its('content') do
      should include 'verify required ca-file /etc/haproxy/ssl/cf-origin-pull.ca',
                     'http-request set-header X-Forwarded-Proto https',
                     'acl canary_opt_in   req.cook(gitlab_canary) -m str -i true',
                     'acl canary_opt_out  req.cook(gitlab_canary) -m str -i false',
                     'http-response set-header GitLab-LB %H',
                     'http-response set-header GitLab-SV %s',
                     'acl backend_available_api nbsrv(api) gt 0'
    end

    # Verifies packhorse loop-prevention ACL and unconditional header strip
    # in the ci-gateway frontend. set-var must appear before del-header so
    # the variable is captured before the header is removed (http-request
    # rules run in declaration order).
    its('content') do
      should match(/http-request set-var\(req\.packhorse_upstream\).*\n.*http-request del-header X-Packhorse-Upstream/)
    end
    its('content') do
      should include 'acl is_packhorse_upstream var(req.packhorse_upstream) -m int gt 0',
                     'acl is_packhorse_repo path_beg /gitlab-org/gitlab.git',
                     'use_backend packhorse if is_packhorse_repo is_git_upload_pack_post METH_POST backend_available_packhorse !is_packhorse_upstream'
    end

    # Verifies the ci-gateway limited API allowlist for runner managers.
    its('content') do
      should include 'acl is_api_runners_verify path_reg -i ^\/api\/v\d\/runners\/verify$',
                     'use_backend api if is_runner_manager is_api_runners_verify METH_POST'
    end

    # Verifies packhorse routing in the main (frontend) https frontend.
    # The loop-prevention header handling and repo ACL must also appear in
    # the https frontend so that the main HAProxy nodes can route to Packhorse.
    its('content') do
      should include 'acl is_git_upload_pack_post path_reg -i \.git\/git-upload-pack$',
                     'acl is_git_new_initial_request path_reg -i ^\/[^\/]+(\/[^\/]+)+\.git\/info\/refs$',
                     'acl is_upload_pack_service urlp_reg(service) -i ^git-upload-pack$'
    end
    its('content') do
      should include 'use_backend packhorse if is_packhorse_repo is_git_upload_pack_post METH_POST backend_available_packhorse !is_packhorse_upstream',
                     'use_backend packhorse if is_packhorse_repo is_git_new_initial_request is_upload_pack_service METH_GET backend_available_packhorse !is_packhorse_upstream'
    end
    its('content') do
      should include 'server packhorse_lb 10.0.1.100:8080 check'
    end

    # Verifies correct template handling in backend definition
    # Also verifies correct behaviour of
    #  - Gitlab::TemplateHelpers::backend_servers_for_lb_zone
    #  - Gitlab::TemplateHelpers::backend_servers_by_pool
    #  - Gitlab::TemplateHelpers::build_ssl_opts
    #  - Gitlab::TemplateHelpers::build_check_opts
    its('content') do
      should include(
               # Check that ssh sends the traffic wrapped in PROXYv2
               'server shell-gke-us-east1-b 10.221.13.40:2222 weight 100 send-proxy-v2',
               # Check that websockets are cookie bound
               'server ws-gke-us-east1-b 10.221.13.19:8181 weight 100 cookie ws-gke-us-east1-b',
               # Check the general template. This includes:
               # - dedupe of check opts and ssl opts
               # - weight & backup assignment
               #
               # - health check in new format
               'option httpchk
  http-check send meth GET uri /-/k8s/api/-/readiness ver HTTP/1.1 hdr Host gitlab.com
  default-server check check-ssl inter 3s fastinter 1s downinter 5s fall 3
  default-server ssl verify none
  # node pool \'api\'
  server api-gke-us-east1-b 10.221.13.25:443 weight 100
  server api-gke-us-east1-c 10.221.14.23:443 weight 100 backup
  server api-gke-us-east1-d 10.221.15.31:443 weight 100 backup
  # node pool \'canary_api\'
  server gke-cny-api 10.216.8.44:443 weight 5
',
               # Validates the TCP check variant of the healthcheck
               'option tcp-check
  default-server check inter 3s fastinter 1s downinter 5s fall 3
  default-server no-ssl
  # node pool \'canary_https_git\'',
               # Validates the SSH-2.0 TCP check variant
               'option tcp-check
  tcp-check expect string "SSH-2.0"
  default-server check no-ssl inter 3s fastinter 1s downinter 5s fall 3
  default-server no-ssl
  # node pool \'ssh\'')
    end
  end
end
