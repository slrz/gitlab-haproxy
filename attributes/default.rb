default['gitlab-haproxy']['chef_vault'] = nil
default['gitlab-haproxy']['chef_vault_item'] = nil
default['gitlab-haproxy']['admin_password'] = nil
default['gitlab-haproxy']['client_timeout'] = '90s'
default['gitlab-haproxy']['server_timeout'] = '90s'
default['gitlab-haproxy']['https_custom_config'] = nil
default['gitlab-haproxy']['worker_chef_query'] = 'role:gitlab-cluster-worker'

default['gitlab-haproxy']['ssl'] = {}
default['gitlab-haproxy']['ssl']['gitlab_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['gitlab_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['ci_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['ci_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['registry_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['registry_key'] = 'use vault' 
default['gitlab-haproxy']['ssl']['pages_crt'] = 'use vault' 
default['gitlab-haproxy']['ssl']['pages_key'] = 'use vault' 

default['openssh']['server']['listen_address'] = [ "0.0.0.0:2222" ]
