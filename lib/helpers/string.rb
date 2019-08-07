class String
  MASK_EMAIL_REGEXP = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i.freeze

  def ensure_utf8
    self.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end

  def is_number?
    true if Float(self) rescue false
  end

  def excerpt(length: 100)
    truncate(length, separator: ' ')
  end

  def from_json
    ActiveSupport::JSON.decode(self).deep_symbolize_keys
  end

  def split_name(part)
    name_parts = split(' ')
    case part
    when :first
      name_parts.first
    when :last
      name_parts.last
    end
  end

  def between_markers(s, e)
    self[/#{Regexp.escape(s)}(.*?)#{Regexp.escape(e)}/m, 1]
  end

  def sub_with_direction(direction: :from_top, subs:, replacement:)
    direction ||= :from_top
    direction = direction.to_sym
    result = self
    case direction
      when :from_top
        result = self.sub(subs, replacement)
      when :from_bottom
        pieces = self.rpartition(subs)
        (pieces[(pieces.find_index subs)] = replacement) rescue nil
        result = pieces.join
    end
    result
  end

  def paragraphize
    str = gsub("\r\n", "\n")

    str = str.sub "\n\n\n", "<br />\n\n" while str.include? "\n\n\n"

    if str.include? "\n\n"
      str = str.split "\n\n"
      str = str.map { |paragraph| "<p>#{paragraph}</p>" }.join
    end

    str = str.gsub "\n", "<br />"
    str.html_safe
  end

  def as_display_name(setting = :initialize_first)
    return '' if self.blank?
    return self.mask_email if self.include?('@')
    case setting.to_sym
      when :initialize_first
        self.strip.gsub(/\s+.+\s+/, ' ').sub(/(?<=\s\S).+/, '.').split.map(&:capitalize) * ' '
      when :initialize_all
        array = self.strip.gsub(/\s+.+\s+/, ' ').split
        res = "#{array.first.first.capitalize}."
        res += " #{array.last.first.capitalize}." if array.length > 1
        res
      else
        self
    end
  end

  def as_initials
    return '' if blank?
    gsub(/\s+.+\s+/, ' ').scan(/(\A\w|(?<=\s)\w)/).flatten.join.upcase
  end

  def mask_email
    gsub(MASK_EMAIL_REGEXP, '***@***.***')
  end

  def valid_as_uri?
    uri = URI.parse(self)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end
