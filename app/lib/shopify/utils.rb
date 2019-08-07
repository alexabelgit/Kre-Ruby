module Shopify
  class Utils

    INJECTION_COMMENT = { start: '{% comment %} HelpfulCrowd injected code. Please do not change or remove this and the next comment {% endcomment %}',
                          end:   '{% comment %} HelpfulCrowd injected code. Please do not change or remove this and the previous comment {% endcomment %}' }

    def self.auto_inject_supported?(store: nil, name: nil)
      name = store.present? ? store.settings(:shopify).theme_name : name
      load_theme_config.select{ |x| x['theme'] == name }.any?
    end

    def self.get_theme_config(theme_name: , injection_id: nil)
      current_config = load_theme_config.select{ |x| x['theme'] == theme_name }.first
      return nil unless current_config
      return current_config['injections'] unless injection_id

      injection = current_config['injections'].select{ |x| x['id'] == injection_id }.first
      injection.symbolize_keys!
      injection
    end

    def self.perform_injection(injection:, content:)
      indent      = ' ' * (injection[:indent]      || 0)
      hook_indent = ' ' * (injection[:hook_indent] || 0)
      replacement = construct_replacement(type: injection[:inject_type], code: injection[:code], hook: injection[:hook], indent: indent, hook_indent: hook_indent)
      case injection[:inject_type]
        when 'last'
          content += replacement
        when 'before_hook'
          replacement = replacement
          content     = content.sub_with_direction(direction:   injection[:hook_lookup],
                                                   subs:        injection[:hook],
                                                   replacement: replacement)
        when 'after_hook'
          content = content.sub_with_direction(direction:   injection[:hook_lookup],
                                               subs:        injection[:hook],
                                               replacement: replacement)
      end
      {
        content:     content,
        replacement: replacement
      }
    end

    def self.perform_removal(content:)
      markers_detected = true
      temp_uuids       = []
      while markers_detected
        between_markers  = content.between_markers(INJECTION_COMMENT[:start], INJECTION_COMMENT[:end])
        markers_detected = between_markers.present?
        if markers_detected
          block_for_removal = "#{INJECTION_COMMENT[:start]}#{between_markers}#{INJECTION_COMMENT[:end]}"
          if between_markers.lines.count <= 5
            content.gsub!(block_for_removal, '')
          else
            uuid = SecureRandom.uuid
            content.sub!(INJECTION_COMMENT[:start], uuid)
            temp_uuids << uuid
          end
        end
      end
      temp_uuids.each do |uuid|
        content.sub!(uuid, INJECTION_COMMENT[:start])
      end
      content
    end

    def self.auto_remove_status_list(store)
      JSON.parse("[#{store.settings(:shopify).auto_remove_status}]")
    end

    private_class_method def self.load_theme_config
      YAML.load_file(Rails.root.join('app', 'services', 'sync', 'shopify', 'config', 'themes.yaml'))
    end

    private_class_method def self.construct_replacement(type:, code:, hook:, indent:, hook_indent:)
      replacement   = ''
      case type
        when 'last'
          replacement = "\n#{indent}#{INJECTION_COMMENT[:start]}\n#{indent}#{code}\n#{indent}#{INJECTION_COMMENT[:end]}"
        when 'before_hook'
          replacement = "\n#{indent}#{INJECTION_COMMENT[:start]}\n#{indent}#{code}\n#{indent}#{INJECTION_COMMENT[:end]}\n\n#{hook_indent}#{hook}"
        when 'after_hook'
          replacement = "#{hook}\n\n#{indent}#{INJECTION_COMMENT[:start]}\n#{indent}#{code}\n#{indent}#{INJECTION_COMMENT[:end]}\n"
      end
    end
  end
end
