control 'haproxy-flavor-checks' do
  impact 1.0
  title 'Tests HAProxy settings for flavor specific configuration (flavor: pages)'
  only_if { command('lsb_release -rs').stdout !~ /18\.04/ }
  desc '
    This control ensures that:
      * specific configuration settings for the pages flavor
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
      should_not include 'ssl-mode-async' # This is disabled in overrides
    end
    its('content') do
      should include 'tune.ssl.lifetime 900'
    end
    its('content') do
      should include 'spread-checks 4'
    end
    its('content') do
      should include 'hard-stop-after 20m'
    end
    # defaults section
    its('content') do
      should include 'retry-on conn-failure'
    end
    its('content') do
      should_not include 'option redispatch' # This is disabled in overrides
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
    # pages backend should use the TCP logstring
    its('content') do
      should include 'log-format %ci:%cp\ [%t]\ %ft\ %sslv\ %b/%s\ %Tw/%Tc/%Tt\ %B\ %U\ %ts\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq'
    end

    # Peer section is being included
    its('content') do
      should include('peers pages-peers
  bind 0.0.0.0:32769',
                     'server fe-pages-02-lb-gprd 93.184.216.34:32769')
    end
    # Validates that local peer detection works, and no IP:port pair is inserted for it
    its('content') { should match /32769\n  server tk-haproxy-pages-ubuntu-20-04-x64-\S+ \n/ }

    # backend & frontend availability. Tests Gitlab::TemplateHelpers::select_backends & select_frontends
    %w(pages_https pages_http).each do |name|
      its('content') do
        should include "backend #{name}"
      end
      its('content') do
        should include "frontend #{name}"
      end
    end

    # Tests Gitlab::TemplateHelpers::merge_check_frontends and its property merging
    its('content') do
      should include 'frontend check_https
  bind 0.0.0.0:8002 tfo
  mode http',
                     'monitor-uri /-/available-https
  monitor fail if !backend_available_pages_https'
    end

    # Verifies correct template handling in frontend defintion
    its('content') do
      should_not include 'verify required ca-file /etc/haproxy/ssl/cf-origin-pull.ca',
                         'acl backend_available_api nbsrv(api) gt 0',
                         'http-request set-header X-Forwarded-Proto https',
                         'acl canary_opt_in   req.cook(gitlab_canary) -m str -i true',
                         'acl canary_opt_out  req.cook(gitlab_canary) -m str -i false'
      should include 'http-request set-header X-Forwarded-Proto http',
                     'http-response set-header GitLab-LB %H',
                     'http-response set-header GitLab-SV %s',
                     'acl backend_available_pages_https nbsrv(pages_https) gt 0'
    end

    # We should not enable incoming PROXYv2 on pages
    its('content') { should_not include 'tcp-request connection expect-proxy layer4' }

    # Verifies correct template handling in backend defintion
    # Also verifies correct behaviour of
    #  - Gitlab::TemplateHelpers::backend_servers_for_lb_zone
    #  - Gitlab::TemplateHelpers::backend_servers_by_pool
    #  - Gitlab::TemplateHelpers::build_ssl_opts
    #  - Gitlab::TemplateHelpers::build_check_opts
    its('content') do
      should include(
               # Check that the TLS traffic is forwarded with PROXYv2
               'server pages-us-east1-b 10.221.13.5:443 weight 100 send-proxy-v2',
               # Check the general template. This includes:
               # - dedupe of check opts and ssl opts
               # - no-ssl being returned for plain text backends
               # - weight & backup assignment
               # - health check in new format
               'option httpchk
  http-check send meth GET uri /-/readiness hdr Host gitlab.com
  default-server check inter 3s fastinter 1s downinter 5s fall 3
  default-server no-ssl
  # node pool \'pages\'
  server pages-us-east1-b 10.221.13.5:80 weight 100
  server pages-us-east1-c 10.221.14.130:80 weight 100 backup
  server pages-us-east1-d 10.221.15.6:80 weight 100 backup
  # node pool \'canary_pages\'
  server gke-cny-pages 10.216.8.25:80 weight 5',
               # additionally validates the pages_https-backend check variant of the healthcheck with the port being overridden, as the nodes are connected to via PROXYv2 on port 443 normally
               'option httpchk
  http-check send meth GET uri /-/readiness hdr Host gitlab.com
  default-server check inter 3s fastinter 1s downinter 5s fall 3 port 80
  default-server no-ssl
  # node pool \'pages\'
  server pages-us-east1-b 10.221.13.5:443 weight 100 send-proxy-v2
  server pages-us-east1-c 10.221.14.130:443 weight 100 backup send-proxy-v2
  server pages-us-east1-d 10.221.15.6:443 weight 100 backup send-proxy-v2
  # node pool \'canary_pages\'
  server gke-cny-pages 10.216.8.25:443 weight 5 send-proxy-v2')
    end
  end
end
