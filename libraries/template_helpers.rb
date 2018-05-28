module Gitlab
  module TemplateHelpers
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
