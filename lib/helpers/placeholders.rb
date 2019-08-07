class Placeholders

  FRONT_MAILER_SUBJECT = {
    customer_name:       %w(customer name),
    customer_first_name: %w(customer first_name),
    store_name:          %w(store name)
  }

  REVIEW_REQUEST_MAIL_BODY = {
    customer_name:       '@review_request.customer.name',
    customer_first_name: '@review_request.customer.first_name',
    order_number:        '@review_request.public_id',
    products:            "render 'front_mailer/products'",
    store_name:          '@store.name',
    store_link:          'link_to(@store.name, @store.url)',
    store_url:           '@store.url'
  }

  REVIEW_COMMENT_MAIL_BODY = {
    customer_name:       '@comment.commentable.customer.name',
    customer_first_name: '@comment.commentable.customer.first_name',
    product_name:        '@comment.commentable.product.name',
    product_link:        'call_to_action(t("view_product", scope: "front.mailer.helpers.call_to_action"), @comment.commentable.product.url)',
    product_url:         '@comment.commentable.product.url',
    reply:               'span_quote(@comment.body)',
    review:              'span_quote(@comment.commentable.feedback)',
    store_name:          '@store.name',
    store_link:          'link_to(@store.name, @store.url)',
    store_url:           '@store.url'
  }

  REVIEW_FOLLOWUP_MAIL_BODY = {
    customer_name:       '@review.customer.name',
    customer_first_name: '@review.customer.first_name',
    product_name:        '@review.product.name',
    product_url:         '@review.product.url',
    store_name:          '@store.name',
    store_link:          'link_to(@store.name, @store.url)',
    store_url:           '@store.url'
  }

  QUESTION_COMMENT_MAIL_BODY = {
    answer:              'span_quote(@comment.body)',
    customer_name:       '@comment.commentable.customer.name',
    customer_first_name: '@comment.commentable.customer.first_name',
    product_name:        '@comment.commentable.product.name',
    product_link:        'call_to_action(t("view_product", scope: "front.mailer.helpers.call_to_action"), @comment.commentable.product.url)',
    product_url:         '@comment.commentable.product.url',
    question:            'span_quote(@comment.commentable.body)',
    store_name:          '@store.name',
    store_link:          'link_to(@store.name, @store.url)',
    store_url:           '@store.url'
  }

  REVIEW_FACEBOOK_POST = {
    customer_name:       'display_name',
    customer_first_name: 'display_first_name',
    feedback:            'feedback',
    product_name:        'reviewable.name',
    rating:              'rating.to_stars'
  }

  REVIEW_TWEET = {
    customer_name:       'display_name',
    customer_first_name: 'display_first_name',
    feedback:            'feedback',
    product_name:        'reviewable.name',
    rating:              'rating.to_stars'
  }

  QUESTION_FACEBOOK_POST = {
    customer_name:       'display_name',
    customer_first_name: 'display_first_name',
    product_name:        'product.name',
    question:            'body',
    answer:              "comment.present? ? comment.body : ''"
  }

  QUESTION_TWEET = {
    customer_name:       'display_name',
    customer_first_name: 'display_first_name',
    product_name:        'product.name',
    question:            'body',
    answer:              "comment.present? ? comment.body : ''"
  }

  COUPON_CODE = {
    code:                '@coupon_code.present? ? @coupon_code.code : self.code'
  }

  DISCOUNT_COUPON = {
    discount_amount:     '@discount_coupon.present? ? @discount_coupon.discount_text : self.discount_text',
    coupon_valid_from:   '@discount_coupon.present? ? @discount_coupon.valid_from_text : self.valid_from_text',
    coupon_valid_until:  '@discount_coupon.present? ? @discount_coupon.valid_until_text : self.valid_until_text'
  }

  PROMOTION = {
    promotion_starts_at: '@promotion.present? ? @promotion.starts_at_text : self.starts_at_text',
    promotion_ends_at:   '@promotion.present? ? @promotion.ends_at_text : self.ends_at_text'
  }

  def self.parse(str, keys, object, safe, paragraphize, review_request, review)
    str = CGI::escape_html(str) unless safe

    keys.select{ |x| str.include?("[#{ x }]") }.each do |key, value|
      replacement = ''

      promotion = Promotion.find_by_name(key)
      if promotion.present?
        replacement = promotion.instance_eval(value)
      elsif value.is_a?(String)
        replacement = object.instance_eval(value)
      elsif value.is_a?(Array)
        replacement = object

        value.each do |attr|
          replacement = replacement.send(attr)
        end
      end

      if replacement.include?('<table>') || replacement.include?('<div') || replacement.include?('<p>')
        if str.include?("<p>[#{ key }]</p>")
          str = str.gsub("<p>[#{ key }]</p>", replacement)
        end
      end
      str = str.gsub("[#{ key }]", replacement)
    end

    str
  end

end

class String
  def parse_placeholders(keys, object, safe=false, paragraphize=false, review_request=nil, review=nil)
    Placeholders.parse(self, keys, object, safe, paragraphize, review_request, review)
  end
end
