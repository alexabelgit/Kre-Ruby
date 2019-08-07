module Shopify
  class UrlSanitizer
    MY_SHOPIFY_DOMAIN = 'myshopify.com'.freeze
    VALIDATION_REGEXP = /^[a-z0-9][a-z0-9\-]*[a-z0-9]\.#{Regexp.escape(MY_SHOPIFY_DOMAIN)}$/
    STORE_HANDLE_REGEXP = /(?<store_handle>.+)\.#{MY_SHOPIFY_DOMAIN}$/

    def self.myshopify_domain
      MY_SHOPIFY_DOMAIN
    end

    def self.sanitize_shop_domain(shop_domain)
      name = shop_domain.to_s.strip
      name += ".#{myshopify_domain}" if !name.include?("#{myshopify_domain}") && !name.include?(".")

      name.sub!(%r|https?://|, '')

      u = URI("http://#{name}")
      u.host if u.host&.match VALIDATION_REGEXP
    rescue URI::InvalidURIError
      nil
    end

    def self.extract_shop_handle(url)
      sanitized_domain = sanitize_shop_domain url
      return nil if sanitized_domain.blank?
      sanitized_domain.match(STORE_HANDLE_REGEXP)[:store_handle]
    end
  end
end
