class TemplatePresenter
  attr_reader :sample_review_comment,
              :sample_question_comment,
              :sample_question_body,
              :sample_store_logo,
              :sample_products_quantity,
              :sample_product_1_image,
              :sample_product_1_name,
              :sample_product_2_image,
              :sample_product_2_name,
              :sample_rating,
              :sample_customer_name,
              :sample_feedback,
              :sample_order_number


  def initialize(store, view_context = ActionView::Base.new)
    @store = store
    @view  = view_context

    @sample_review               = @store.reviews.any?                          ? @store.reviews.last                           : false
    @sample_question             = @store.questions.any?                        ? @store.questions.answered.last                         : false

    @sample_products             = @store.products.active.any?                  ? @store.products.active.last(2)                : false
    @sample_products_quantity = @sample_products.any? ? @sample_products.count : 1

    @sample_product = @sample_products.first if @sample_products.any?
    # @sample_product_1_url          = @sample_product.present?                    ? @sample_product.url                           : @store.url + '/your_awesome_product'
    @sample_product_1_name         = @sample_product.present?                     ? @sample_product.name                          : 'Your awesome product'
    @sample_product_1_image        = @sample_product.present?                     ? @sample_product.featured_image.small.url : ApplicationController.helpers.cl_image_path(ENV['DEFAULT_PUBLIC_ID_FOR_FEATURED_IMAGE'], width: 150, height: 100, crop: :fill)

    if @sample_products.count > 1
      @sample_product_2 = @sample_products.second
      # @sample_product_2_url          = @sample_product_2.url
      @sample_product_2_name         = @sample_product_2.name
      @sample_product_2_image        = @sample_product_2.featured_image.small.url
    end

    @sample_rating               = @sample_review.present?                      ? @sample_review.rating.to_stars                : 5.to_stars
    @sample_feedback             = @sample_review.present?                      ? @sample_review.feedback                       : 'The product was in excellent condition and the customer support experience was just great! thanks so much'
    @sample_question_body        = @sample_question.present?                    ? @sample_question.body                         : 'Does this come in a gift wrap?'
    @sample_review_comment       = @sample_review && @sample_review.comment     ? @sample_review.comment.body                   : 'Thank you, your feedback is appreciated.'
    @sample_question_comment     = @sample_question && @sample_question.comment ? @sample_question.comment.body                 : 'Thanks for asking. Please visit the Q&A section on product page to view full answer.'
    @sample_customer_name        = @sample_review.present?                      ? @sample_review.customer.name                  : 'Test Customer'
    @sample_customer_first_name  = @sample_review.present?                      ? @sample_review.customer.display_first_name    : 'Test'
    @sample_order_number         = @store.orders.any?                           ? @store.orders.last.public_id                  : '159'
    @sample_store_logo           = @store.logo.present?                         ? @store.logo.tiny.url.to_s                     : "https://placehold.it/100x100"
  end

  def sample_data_hash
    promotions                   = @store.promotions
    active_promotions            = promotions.active
    promotions_placeholders_hash = active_promotions.map{|p| { p.name.to_sym => p.parse_template } }.reduce(Hash.new, :merge)
    inactive_promotions          = promotions - active_promotions
    promotions_placeholders_hash = inactive_promotions.map{|p| { p.name.to_sym => ''} }.reduce(promotions_placeholders_hash, :merge)

    sample_data = { customer_name:       @sample_customer_name,
                    customer_first_name: @sample_customer_first_name,
                    order_number:        @sample_order_number,
                    product_link:        @view.content_for(:sample_product_link),
                    product_name:        @sample_product_1_name,
                    product_url:         @sample_product_1_url,
                    products:            @view.content_for(:sample_purchased_products),
                    rating:              @sample_rating,
                    reply:               @view.content_for(:sample_reply).present?    ? @view.content_for(:sample_reply)    : @sample_review_comment,
                    answer:              @view.content_for(:sample_answer).present?   ? @view.content_for(:sample_answer)   : @sample_question_comment,
                    review:              @view.content_for(:sample_review).present?   ? @view.content_for(:sample_review)   : @sample_feedback,
                    question:            @view.content_for(:sample_question).present? ? @view.content_for(:sample_question) : @sample_question_body,
                    store_link:          @view.link_to(@store.name, 'javascript:void(0)'),
                    store_name:          @store.name,
                    store_url:           @store.url }.merge!(promotions_placeholders_hash)
    sample_data
  end

end
