require 'resolv'

# rubocop:disable Style/ClassVars # We need class variables on the module.
module Gitlab
  module TemplateHelpers
    # These variables are all filled in self.initialize
    @@node = nil
    @@flavor = ''
    @@backend_servers = nil
    @@chef_attribute_settings = nil
    @@peers = nil
    @@enabled_backends = nil
    @@enabled_frontends = nil
    @@check_frontends = nil

    def self.initialize(node)
      @@node = node
      @@flavor = @@node['gitlab-haproxy']['flavor']
      select_frontends
      select_backends
      merge_check_frontends
      merge_settings
      resolve_peers
      backend_servers_for_lb_zone(
        node['gitlab-haproxy'][@@flavor]['backend'],
        node.to_h.dig('gce', 'instance', 'zone')
      )
    end

    def cookbook_version
      @@node.run_context.cookbook_collection['gitlab-haproxy'].metadata.version
    end

    def get_attribute(*query)
      @@node.to_h.dig(*query)
    end
    module_function :get_attribute # Makes this available inside static module functions.

    def peers
      @@peers
    end

    def flavor
      @@flavor
    end

    def enabled_backends
      @@enabled_backends
    end

    def enabled_frontends
      @@enabled_frontends
    end

    def check_frontends
      @@check_frontends
    end

    def chef_attribute_settings(*query)
      @@chef_attribute_settings.dig(*query)
    end

    def admin_password
      @@node.run_state['HAP_secrets']['admin_password']
    end

    def filter_certificates(wanted)
      available = @@node.run_state['HAP_available_certificates']
      certs = []
      return certs if available.nil? || wanted.nil?
      wanted.each do |cert|
        raise "requested certificate #{cert} not available on disk." unless available.include? cert
        certs << cert
      end
      certs
    end

    # The agent-check options for a server line, or nil when the backend is
    # not enrolled. The agent-send identity is the KV key the agent looks
    # up: <backend>/<server> under the agent's kv-prefix.
    def build_agent_check_opts(backend_name, server_name)
      agent = get_attribute('gitlab-haproxy', 'agent') || {}
      return unless agent['enable'] && (agent['check_backends'] || []).include?(backend_name)

      host, port = agent['listen_addr'].split(':')
      "agent-check agent-addr #{host} agent-port #{port} agent-send \"#{backend_name}/#{server_name}\\n\" agent-inter #{agent['check_inter']}"
    end

    def build_check_opts(backend_name)
      flavored_attrs = get_attribute('gitlab-haproxy', @@flavor) || {}
      "#{flavored_attrs.dig(backend_name, 'check_opts')} #{flavored_attrs['default_check_opts']}".sub(/port\s+\d+/, '').squeeze(' ').strip
    end

    def build_ssl_opts(backend_name, fallback_name = '')
      flavored_attrs = get_attribute('gitlab-haproxy', @@flavor) || {}
      ssl = "#{flavored_attrs.dig(backend_name, 'ssl_verify') || flavored_attrs['ssl_verify']}".squeeze(' ').strip
      fallback_ssl = "#{flavored_attrs.dig(fallback_name, 'ssl_verify') || flavored_attrs['ssl_verify']}".squeeze(' ').strip
      if ssl.start_with?('ssl') || ssl.start_with?('no-ssl')
        ssl
      else
        fallback_ssl.start_with?('ssl') ? fallback_ssl : 'no-ssl'
      end
    end

    def backend_servers_by_pool(pool_name, fallback_pool_name)
      servers = []
      fallback_pool_name ||= pool_name
      backend_check_opts = build_check_opts(pool_name)
      backend_ssl_opts = build_ssl_opts(pool_name, fallback_pool_name)

      send_proxy_v2 = get_attribute('gitlab-haproxy', @@flavor, pool_name, 'send-proxy-v2')
      send_proxy_v2 ||= get_attribute('gitlab-haproxy', @@flavor, 'enable_https_proxyv2')

      port = get_attribute('gitlab-haproxy', @@flavor, pool_name, 'server_port')
      if send_proxy_v2
        # Compatibility for pages port numbers
        port ||= get_attribute('gitlab-haproxy', pool_name, 'https_proxyv2_backend_listen_port')
        port ||= get_attribute('gitlab-haproxy', fallback_pool_name, 'https_proxyv2_backend_listen_port')
      end

      port ||= get_attribute('gitlab-haproxy', @@flavor, fallback_pool_name, 'server_port')
      port ||= get_attribute('gitlab-haproxy', pool_name, 'https_backend_listen_port')
      port ||= get_attribute('gitlab-haproxy', fallback_pool_name, 'https_backend_listen_port')
      port ||= get_attribute('gitlab-haproxy', @@flavor, 'https_backend_listen_port')
      port ||= get_attribute('gitlab-haproxy', pool_name, 'backend_port')
      port ||= get_attribute('gitlab-haproxy', fallback_pool_name, 'backend_port')
      port ||= get_attribute('gitlab-haproxy', @@flavor, 'backend_port')

      weight = get_attribute('gitlab-haproxy', @@flavor, pool_name, 'default_weight')
      weight ||= get_attribute('gitlab-haproxy', @@flavor, fallback_pool_name, 'default_weight')
      weight ||= get_attribute('gitlab-haproxy', pool_name, 'default_weight')
      weight ||= get_attribute('gitlab-haproxy', fallback_pool_name, 'default_weight')
      weight ||= get_attribute('gitlab-haproxy', @@flavor, 'default_weight')

      @@backend_servers['all'][pool_name].each do |name, ip|
        servers << {
          'name' => name,
          'ip' => ip,
          'port' => port.to_i,
          'check_opts' => backend_check_opts,
          'weight' => weight.to_i,
          'active' => @@backend_servers['active'][pool_name].key?(name),
          'send_proxy_v2' => send_proxy_v2 || false,
          'ssl_opts' => backend_ssl_opts,
        }
      end

      servers
    end

    def self.merge_check_frontends
      flavor = @@flavor
      check_frontends = get_attribute('gitlab-haproxy', 'check_frontends')
      merged = Hash.new { |h, k| h[k] = {} }

      return merged if check_frontends[flavor].nil?

      check_frontends[flavor].each do |frontend_name, _|
        next unless (check_frontends[flavor][frontend_name]['backends'] || []).any?
        # We should render this one in the first place
        merged[frontend_name] = Hash.new { |h, k| h[k] = {} }
        merged[frontend_name]['backends'] = check_frontends[flavor][frontend_name]['backends']
        merged[frontend_name]['uri'] = check_frontends[flavor][frontend_name]['uri'] || check_frontends['default'][frontend_name]['uri']
        merged[frontend_name]['port'] = check_frontends[flavor][frontend_name]['port'] || check_frontends['default'][frontend_name]['port']
      end

      @@check_frontends = merged
    end

    def self.select_frontends
      frontends = []
      flavor = @@flavor

      map = get_attribute('gitlab-haproxy', 'enabled_frontends')
      raise 'no frontends flavor map configured' if map.nil?
      raise 'unknown flavor' if map[flavor].nil?

      map[flavor].each do |frontend_name|
        frontends << frontend_name
      end

      @@enabled_frontends = frontends.sort
    end

    def self.select_backends
      backends = []
      flavor = @@flavor

      map = get_attribute('gitlab-haproxy', 'enabled_backends')
      raise 'no backends flavor map configured' if map.nil?
      raise 'unknown flavor' if map[flavor].nil?

      map[flavor].each do |backend_name|
        backends << backend_name
      end

      @@enabled_backends = backends.sort
    end

    def self.merge_settings
      flavor = @@flavor
      input = get_attribute('gitlab-haproxy', 'config')
      settings = Hash.new { |h, k| h[k] = {} }
      settings['global'] = Hash.new { |h, k| h[k] = {} }
      settings['defaults'] = Hash.new { |h, k| h[k] = {} }

      input['default']['global'].each do |setting, value|
        settings['global'][setting] = value unless value.nil?
      end

      input['default']['defaults'].each do |setting, value|
        settings['defaults'][setting] = value unless value.nil?
      end

      unless input[flavor].nil?
        # This copies the frontend settings 1:1.
        unless input[flavor]['frontend'].nil?
          input[flavor]['frontend'].each do |section, _|
            settings['frontend'][section] = input[flavor]['frontend'][section].to_h
          end
        end

        # This copies the backend settings 1:1.
        unless input[flavor]['backend'].nil?
          input[flavor]['backend'].each do |section, _|
            settings['backend'][section] = input[flavor]['backend'][section].to_h
          end
        end

        unless input[flavor]['global'].nil?
          input[flavor]['global'].each do |setting, value|
            if value.nil?
              settings['global'].delete(setting)
            else
              settings['global'][setting] = value
            end
          end
        end

        unless input[flavor]['defaults'].nil?
          input[flavor]['defaults'].each do |setting, value|
            if value.nil?
              settings['defaults'].delete(setting)
            else
              settings['defaults'][setting] = value
            end
          end
        end
      end

      @@chef_attribute_settings = settings
    end

    def self.resolve_peers
      flavor = @@flavor
      dynamic_lookup_enabled = get_attribute('gitlab-haproxy', flavor, 'peers', 'dynamic_lookup')
      peers =
        if dynamic_lookup_enabled
          dynamic_peer_lookup
        else
          get_attribute('gitlab-haproxy', flavor, 'peers', 'servers')
        end
      hostname = get_attribute('hostname')
      new_peers = Hash.new { |h, k| h[k] = {} }

      # Some flavors don't have peers
      if peers.nil? || peers.empty?
        @@peers = new_peers
        return
      end

      peers.each do |name, network|
        # In kitchen we have a `kitchen-vm-under-test` peer.
        # This is to ensure a kitchen config will render peers properly.
        # But because hostnames are dynamic in kitchen, we need to patch it.
        # So the kitchen VM will take the peer config from `kitchen-vm-under-test`
        name = hostname if name == 'kitchen-vm-under-test'
        new_peers[name] = Resolv.getaddress(network[0])
      end

      @@peers = new_peers
    end

    def self.dynamic_peer_lookup
      Chef::Log.warn("Querying for peers in the #{@@node.chef_environment} environment with flavor #{@@flavor}")
      node_filter =
        if @@node['gitlab-haproxy']['peering_key']
          "gitlab-haproxy_peering_key:#{@@node['gitlab-haproxy']['peering_key']}"
        else
          "gitlab-haproxy_flavor:#{@@flavor}"
        end
      peers = Chef::Search::Query.new.search(:node, "chef_environment:#{@@node.chef_environment} AND #{node_filter}")[0]
      port = get_attribute('gitlab-haproxy', @@flavor, 'peers', 'port')

      servers = {}

      peers.each do |peer|
        next if peer['gitlab-haproxy']['skip_peering']
        # Don't allow a node to dynamically discover itself.
        next if peer.name == @@node.name

        shortname = peer.name.split('.').first
        Chef::Log.debug("Adding peer #{shortname} with fqdn: #{peer['fqdn']} to my list of peers to resolve.")
        servers[shortname] = [peer['fqdn'], port]
      end

      servers[@@node['hostname']] = [@@node['fqdn'], port]

      servers.sort
    end

    def self.backend_servers_for_lb_zone(backend_cfg, zone_id)
      # Extract the name from the full zone identifier, ex: projects/65580314219/zones/us-east1-c
      lb_zone = zone_id && File.basename(zone_id)

      servers = Hash.new { |h, k| h[k] = {} }

      # There are no servers to return
      if backend_cfg.nil? || (!backend_cfg.key?('servers') && !backend_cfg.key?('essential'))
        return servers
      end

      if !lb_zone || !backend_cfg['servers'].key?(lb_zone)
        # If there is no LB zone or if there are no servers provided for the LB zone,
        # fallback to the 'default' zone
        lb_zone = 'default'
      end

      # Merge all availability zones (all keys under backend_cfg['servers']) into a single server list
      servers['all'] = backend_cfg['servers'].values.reduce(&:deep_merge)

      # Set the default active servers to an empty server config
      servers['all'].each do |backend, _server|
        servers['active'][backend] = {}
      end

      # Build up an active server list selecting servers that only match the zone of the lb or the zone named default
      backend_cfg['servers'].each do |server_zone, server|
        servers['active'].deep_merge!(server) if lb_zone == server_zone || server_zone == 'default'
      end

      backend_cfg['essential'].each do |backend|
        if servers['active'][backend].empty?
          raise "Essential backend #{backend} has zero active servers configured: #{servers['active']}, aborting!"
        end
      end

      @@backend_servers = servers
      servers
    end

    def formatted_custom_config(config, padding = 4)
      return '' if config.nil?

      string_padding = ' ' * padding

      if config.is_a?(Array)
        config.map { |line| "#{string_padding}#{line}" }.join("\n")
      else
        "#{string_padding}#{config}"
      end
    end
  end
end
