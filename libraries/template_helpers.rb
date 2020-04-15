module Gitlab
  module TemplateHelpers
    def self.backend_servers_for_lb_zone(backend_cfg, zone_id)
      # extract the name from the full
      # zone identifier, ex: projects/65580314219/zones/us-east1-c
      lb_zone = zone_id && File.basename(zone_id)
      servers = Hash.new { |h, k| h[k] = {} }

      if !lb_zone || !backend_cfg['servers'].key?(lb_zone)
        # If there is no LB zone or if there are
        # no servers provided for the LB zone, fallback
        # to the 'default' zone
        lb_zone = 'default'
      end

      # Merge all availability zones (all keys under backend_cfg['servers'])
      # into a single server list
      servers['all'] = backend_cfg['servers'].values.reduce(&:deep_merge)

      # Build up an active server list selecting servers
      # that only match the zone of the lb
      backend_cfg['servers'].each do |server_zone, server|
        servers['active'].update(server) if lb_zone == server_zone
      end

      backend_cfg['essential'].each do |backend|
        if servers['active'][backend].empty?
          raise "Essential backend #{backend} has zero active servers configured: #{servers['active']}, aborting!"
        end
      end

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
