module Gitlab
  module HAProxyCookbook
    def gitlab_haproxy_secrets
      if (chef_vault = node['gitlab-haproxy']['chef_vault'])
        include_recipe 'chef-vault'

        chef_vault_item(chef_vault, node['gitlab-haproxy']['chef_vault_item'])
      else
        secrets_hash = node['gitlab-haproxy']['secrets']

        get_secrets(secrets_hash['backend'], secrets_hash['path'], secrets_hash['key'])
      end
    end
  end
end

Chef::DSL::Recipe.include Gitlab::HAProxyCookbook
