module Gitlab
  module TemplateHelpers
    def self.backend_servers_for_lb_zone(backend_cfg, zone_id)
      # extract the name from the full
      # zone identifier, ex: projects/65580314219/zones/us-east1-c
      zone = zone_id && File.basename(zone_id)

      if !zone || !backend_cfg['servers'].key?(zone)
        # If there is no LB zone or if there are
        # no servers provided for the LB zone, fallback
        # to the 'default' zone
        return _zone_servers(backend_cfg, 'default')
      end

      _zone_servers(backend_cfg, zone)
    end

    def self._zone_servers(backend_cfg, zone)
      essential = backend_cfg['essential']
      servers = backend_cfg['servers'][zone]
      essential.each do |backend|
        if servers[backend].empty?
          raise "Essential backend #{backend} has zero servers configured: #{servers}, aborting!"
        end
      end
      backend_cfg['servers'][zone]
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
