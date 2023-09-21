control 'haproxy-flavor-checks' do
  impact 1.0
  title 'Tests HAProxy settings for flavor specific configuration (flavor: registry)'
  only_if { command('lsb_release -rs').stdout !~ /18\.04/ }
  desc '
    This control ensures that:
      * specific configuration settings for the registry flavor
    are present in the HAProxy configuration'

  [
    7331, # stats
    80, # http
    443, # https
    8001, # check_http
    8002, # check_https
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
      should include 'timeout server 90s'
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
  end

  # General config related flavor differences
  describe file('/etc/haproxy/haproxy.cfg') do
    # nothing should use the TCP logstring
    its('content') do
      should_not include 'log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tw/%Tc/%Tt\ %B\ %U\ %ts\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq'
    end

    # Peer section is being included
    its('content') do
      should include('peers registry-peers
  bind 0.0.0.0:32769',
                     'server fe-registry-02-lb-gprd 93.184.216.34:32769')
    end
    # Validates that local peer detection works, and no IP:port pair is inserted for it
    its('content') { should match /32769\n  server tk-haproxy-registry-ubuntu-20-04-x64-\S+ \n/ }

    # backend availability. Tests Gitlab::TemplateHelpers::select_backends
    %w(registry canary_registry).each do |backend|
      its('content') do
        should include "backend #{backend}"
      end
    end

    # frontend availability. Tests Gitlab::TemplateHelpers::select_frontends
    %w(http https).each do |backend|
      its('content') do
        should include "frontend #{backend}"
      end
    end

    # Tests Gitlab::TemplateHelpers::merge_check_frontends and its property merging
    its('content') do
      should include 'frontend check_https
  bind 0.0.0.0:8002 tfo
  mode http',
                     'monitor-uri /-/available-https
  monitor fail if !backend_available_registry'
    end

    # Verifies correct template handling in frontend defintion
    its('content') do
      should_not include 'verify required ca-file /etc/haproxy/ssl/cf-origin-pull.ca',
                         'acl backend_available_api nbsrv(api) gt 0'

      should include 'http-request set-header X-Forwarded-Proto https',
                     'acl canary_opt_in   req.cook(gitlab_canary) -m str -i true',
                     'acl canary_opt_out  req.cook(gitlab_canary) -m str -i false',
                     'http-response set-header GitLab-LB %H',
                     'http-response set-header GitLab-SV %s',
                     'acl backend_available_registry nbsrv(registry) gt 0'
    end

    # Verifies correct template handling in backend defintion
    # Also verifies correct behaviour of
    #  - Gitlab::TemplateHelpers::backend_servers_for_lb_zone
    #  - Gitlab::TemplateHelpers::backend_servers_by_pool
    #  - Gitlab::TemplateHelpers::build_ssl_opts
    #  - Gitlab::TemplateHelpers::build_check_opts
    its('content') do
      # nothing should be sent via PROXYv2
      should_not include('send-proxy-v2')

      should include(
               # Check the general template. This includes:
               # - dedupe of check opts and ssl opts
               # - weight & backup assignment
               # - health check in new format
               # - health check with expected status codes
               'option httpchk
  http-check send meth GET uri /v2/ ver HTTP/1.1 hdr Host registry.gitlab.com
  http-check expect status 200-299,401
  default-server check inter 2s fastinter 1s downinter 5s fall 3
  default-server no-ssl
  # node pool \'registry\'
  server registry-us-east1-b 10.221.13.41:5000 weight 100
  server registry-us-east1-c 10.221.14.3:5000 weight 100 backup
  server registry-us-east1-d 10.221.15.4:5000 weight 100 backup
  # node pool \'canary_registry\'
  server gke-cny-registry 10.216.8.18:5000 weight 10'
             )
    end
  end
end
