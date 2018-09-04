default['gitlab-haproxy']['secrets']['backend'] = 'chef_vault'
default['gitlab-haproxy']['secrets']['path'] = 'gitlab-cluster-base'
default['gitlab-haproxy']['secrets']['key'] = '_default'

default['gitlab-haproxy']['errors']['503']['title'] = 'An internal server error occured.'
default['gitlab-haproxy']['errors']['503']['subtitle'] = 'Please contact your GitLab administrator.'

default['gitlab-haproxy']['delay_speed_ms'] = '1000'
default['gitlab-haproxy']['timeout_server_ssh'] = '2h'
default['gitlab-haproxy']['timeout_client_fin'] = '5s'
default['gitlab-haproxy']['timeout_server_fin'] = '5s'
default['gitlab-haproxy']['timeout_tunnel'] = '8s'
default['gitlab-haproxy']['listen_address'] = '0.0.0.0'
default['gitlab-haproxy']['timeout_client'] = '90s'
default['gitlab-haproxy']['timeout_server'] = '90s'
default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['api_address'] = '0.0.0.0'

default['gitlab-haproxy']['frontend']['blacklist']['uri'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['internal'] = {}
default['gitlab-haproxy']['frontend']['whitelist']['api'] = {}

default['gitlab-haproxy']['frontend']['peers']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['api']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['api']['servers'] = {}
default['gitlab-haproxy']['frontend']['api']['rate_limit_http_rate_per_minute'] = '600'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['https_git']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['https_git']['servers'] = {}
default['gitlab-haproxy']['frontend']['https']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['https']['rate_limit_frontend_port'] = '4444'
default['gitlab-haproxy']['frontend']['https']['rate_limit_sessions_per_second'] = '10'
default['gitlab-haproxy']['frontend']['https']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['frontend']['registry']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['registry']['backend_port'] = '5000'
default['gitlab-haproxy']['frontend']['registry']['hostname'] = 'registry.gitlab.com'
default['gitlab-haproxy']['frontend']['registry']['httpchk_host'] = node['gitlab-haproxy']['frontend']['registry']['hostname']
default['gitlab-haproxy']['frontend']['registry']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['registry']['servers'] = {}
default['gitlab-haproxy']['frontend']['ssh']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ssh']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['ssh']['port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['servers'] = {}
default['gitlab-haproxy']['frontend']['ssh']['custom_config'] = []
default['gitlab-haproxy']['frontend']['web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['web']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['web']['content_security_policy'] = " default-src 'self';"
default['gitlab-haproxy']['frontend']['web']['servers'] = {}
default['gitlab-haproxy']['frontend']['canary_web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['canary_web']['httpchk_path'] = '/'
default['gitlab-haproxy']['frontend']['canary_web']['content_security_policy'] = " default-src 'self';"
default['gitlab-haproxy']['frontend']['canary_web']['servers'] = {}
default['gitlab-haproxy']['frontend']['websockets']['servers'] = {}
default['gitlab-haproxy']['frontend']['api_rate_limit']['custom_config'] = []
default['gitlab-haproxy']['frontend']['default_check_opts'] = 'inter 2s fastinter 1s downinter 5s fall 3'
default['gitlab-haproxy']['frontend']['registry_check_opts_extra'] = nil

default['gitlab-haproxy']['altssh']['custom_config'] = nil
default['gitlab-haproxy']['altssh']['servers'] = {}

default['gitlab-haproxy']['pages']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['pages']['httpchk_path'] = '/-/readiness'
default['gitlab-haproxy']['pages']['http_custom_config'] = nil
default['gitlab-haproxy']['pages']['https_custom_config'] = nil
default['gitlab-haproxy']['pages']['servers'] = {}
default['gitlab-haproxy']['pages']['http_backend_listen_port'] = 1080
default['gitlab-haproxy']['pages']['https_backend_listen_port'] = 1443

default['gitlab-haproxy']['backend']['rails']['custom_config'] = nil
default['gitlab-haproxy']['backend']['rails']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['backend']['rails']['httpchk_path'] = '/'
default['gitlab-haproxy']['backend']['rails']['rate_limit_frontend_port'] = '7001'
default['gitlab-haproxy']['backend']['rails']['rate_limit_sessions_per_second'] = '20'
default['gitlab-haproxy']['backend']['rails']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['backend']['rails']['servers'] = {}
