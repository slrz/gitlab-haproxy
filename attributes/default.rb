default['gitlab-haproxy']['chef_vault'] = nil
default['gitlab-haproxy']['chef_vault_item'] = nil
default['gitlab-haproxy']['delay_speed_ms'] = '1000'
default['gitlab-haproxy']['timeout_server_ssh'] = '2h'
default['gitlab-haproxy']['timeout_client_fin'] = '5s'
default['gitlab-haproxy']['timeout_server_fin'] = '5s'
default['gitlab-haproxy']['timeout_tunnel'] = '8s'
default['gitlab-haproxy']['listen_address'] = '0.0.0.0'
default['gitlab-haproxy']['timeout_client'] = '90s'
default['gitlab-haproxy']['timeout_server'] = '90s'
default['gitlab-haproxy']['admin_password'] = nil

default['gitlab-haproxy']['ssl'] = {}
default['gitlab-haproxy']['ssl']['gitlab_crt'] = 'use vault'
default['gitlab-haproxy']['ssl']['gitlab_key'] = 'use vault'
default['gitlab-haproxy']['ssl']['ci_crt'] = 'use vault'
default['gitlab-haproxy']['ssl']['ci_key'] = 'use vault'
default['gitlab-haproxy']['ssl']['registry_crt'] = 'use vault'
default['gitlab-haproxy']['ssl']['registry_key'] = 'use vault'
default['gitlab-haproxy']['ssl']['pages_crt'] = 'use vault'
default['gitlab-haproxy']['ssl']['pages_key'] = 'use vault'

default['gitlab-haproxy']['frontend']['api']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['api']['servers'] = {}
default['gitlab-haproxy']['frontend']['https_git']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['https_git']['servers'] = {}
default['gitlab-haproxy']['frontend']['https']['custom_config'] = nil
default['gitlab-haproxy']['frontend']['https']['rate_limit_frontend_port'] = '4444'
default['gitlab-haproxy']['frontend']['https']['rate_limit_sessions_per_second'] = '10'
default['gitlab-haproxy']['frontend']['https']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['frontend']['ssh']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['ssh']['port'] = '22'
default['gitlab-haproxy']['frontend']['ssh']['servers'] = {}
default['gitlab-haproxy']['frontend']['web']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['frontend']['web']['servers'] = {}
default['gitlab-haproxy']['frontend']['websockets']['servers'] = {}

default['gitlab-haproxy']['altssh']['custom_config'] = nil
default['gitlab-haproxy']['altssh']['altssh_servers'] = {}

default['gitlab-haproxy']['pages']['servers'] = {}
default['gitlab-haproxy']['pages']['http_custom_config'] = nil
default['gitlab-haproxy']['pages']['https_custom_config'] = nil

default['gitlab-haproxy']['backend']['rails']['custom_config'] = nil
default['gitlab-haproxy']['backend']['rails']['httpchk_host'] = 'gitlab.com'
default['gitlab-haproxy']['backend']['rails']['rate_limit_frontend_port'] = '7001'
default['gitlab-haproxy']['backend']['rails']['rate_limit_sessions_per_second'] = '20'
default['gitlab-haproxy']['backend']['rails']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['backend']['rails']['servers'] = {}

default['gitlab-haproxy']['backend']['registry']['custom_config'] = nil
default['gitlab-haproxy']['backend']['registry']['httpchk_host'] = 'registry.gitlab.com'
default['gitlab-haproxy']['backend']['registry']['listen_port'] = '5000'
default['gitlab-haproxy']['backend']['registry']['rate_limit_frontend_port'] = '7002'
default['gitlab-haproxy']['backend']['registry']['rate_limit_sessions_per_second'] = '20'
default['gitlab-haproxy']['backend']['registry']['rate_limit_whitelist'] = '127.0.0.1'
default['gitlab-haproxy']['backend']['registry']['servers'] = {}
