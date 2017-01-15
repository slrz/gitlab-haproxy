default['gitlab-haproxy']['chef_vault'] = nil
default['gitlab-haproxy']['chef_vault_item'] = nil
default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['delay_speed_ms'] = '1000'
default['gitlab-haproxy']['timeout_client'] = '90s'
default['gitlab-haproxy']['timeout_server'] = '90s'
default['gitlab-haproxy']['timeout_server_ssh'] = '2h'
default['gitlab-haproxy']['timeout_client_fin'] = '5s'
default['gitlab-haproxy']['timeout_server_fin'] = '5s'
default['gitlab-haproxy']['timeout_tunnel'] = '8s'
default['gitlab-haproxy']['listen_address'] = '0.0.0.0'
default['gitlab-haproxy']['https_custom_config'] = nil
default['gitlab-haproxy']['httpchk_host'] = 'gitlab.com'

default['gitlab-haproxy']['ssl'] = {}
default['gitlab-haproxy']['ssl']['gitlab_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['gitlab_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['ci_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['ci_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['registry_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['registry_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['pages_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['pages_key'] = 'use vault' 

default['gitlab-haproxy']['servers'] = {}
default['gitlab-haproxy']['socket_servers'] = {}
# default['gitlab-haproxy']['servers']['server1'] = '192.168.1.10'
# default['gitlab-haproxy']['servers']['server2'] = '192.168.1.11'

default['openssh']['server']['listen_address'] = [ "0.0.0.0:2222" ]
