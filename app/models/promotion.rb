class Promotion < ApplicationRecord
  belongs_to :store

  has_many :promotion_discount_coupons, dependent: :destroy, inverse_of: :promotion
  has_many :discount_coupons, through: :promotion_discount_coupons

  scope :latest,       -> { order(created_at: :desc) }
  scope :active_dates, -> { where('starts_at <= ?', DateTime.current.beginning_of_day).where('(ends_at IS NULL) OR (ends_at >= ?)', DateTime.current.end_of_day) }
  scope :active,       -> { active_dates.left_outer_joins(:discount_coupons)
                              .where('discount_coupons.id IS NULL ' \
                                     'OR discount_coupons.status = 1 ' \
                                     'OR ((discount_coupons.valid_from <= ?) ' \
                                         'AND (discount_coupons.valid_until IS NULL ' \
                                              'OR discount_coupons.valid_until >= ?) ' \
                                         'AND (discount_coupons.limit IS NULL ' \
                                              'OR discount_coupons.limit > discount_coupons.issue_count))',
                                     DateTime.current.beginning_of_day, DateTime.current.end_of_day) }
                            # The reasons why this code looks this ugly: https://gist.github.com/Babdus/cd44712b7793812978f4b5cc89c69bba

  validates_presence_of     :name, :template, :starts_at
  validates_uniqueness_of   :name, scope: :store_id
  validates                 :ends_at, not_in_past: true
  validate                  :must_start_before_end
  validates_numericality_of :usage_count, greater_than_or_equal_to: 0

  # Before validation set starts to beginning of day and ends to end of day
  before_validation do
    self.starts_at  = starts_at.beginning_of_day  if starts_at.present? && starts_at_changed?
    self.ends_at    = ends_at.end_of_day          if ends_at.present? && ends_at_changed?
  end

  def discount_coupon
    discount_coupons.visible.first
  end

  def available_placeholders
    array = Placeholders::PROMOTION.keys
    array += Placeholders::DISCOUNT_COUPON.keys + Placeholders::COUPON_CODE.keys if self.discount_coupons.any? && self.discount_coupons.first.visible?
    array
  end

  def placeholders_hash_with_empty_values
    placeholders = {}
    if self.discount_coupons.any? && self.discount_coupons.first.visible?
      @discount_coupon = self.discount_coupons.first

      Placeholders::DISCOUNT_COUPON.inject(placeholders) { |hash, (key, value)| hash[key] = eval(value); hash }

      if @discount_coupon.reusable?
        @coupon_code = @discount_coupon.current_coupon_code
      else
        @coupon_code = @discount_coupon.coupon_codes.free.oldest.first || @discount_coupon.current_coupon_code
      end

      Placeholders::COUPON_CODE.inject(placeholders) { |hash, (key, value)| hash[key] = eval(value); hash }
    else
      Placeholders::DISCOUNT_COUPON.inject(placeholders) { |hash, (key, value)| hash[key] = ''; hash }
      Placeholders::COUPON_CODE.inject(placeholders) { |hash, (key, value)| hash[key] = ''; hash }
    end
    Placeholders::PROMOTION.inject(placeholders) { |hash, (key, value)| hash[key] = eval(value); hash }
    placeholders
  end

  def self.placeholders_hash
    self.find_each.reduce(Hash.new){ |hash, p| hash.merge({ p.name.to_sym => 'self.parse_template_and_proceed(review_request: review_request, review: review)' }) }
  end

  def self.available_placeholders
    self.all.map(&:name)
  end

  def parse_template(code: discount_coupon&.coupon_code)
    replacement = template
    Placeholders::PROMOTION.each do |key, value|
      replacement = replacement.gsub("[#{ key }]", self.instance_eval(value))
    end
    Placeholders::DISCOUNT_COUPON.each do |key, value|
      replacement = replacement.gsub("[#{ key }]", discount_coupon.present? ? discount_coupon.instance_eval(value) : '')
    end
    Placeholders::COUPON_CODE.each do |key, value|
      replacement = replacement.gsub("[#{ key }]", code.present? ? code.instance_eval(value) : '')
    end
    replacement
  end

  def parse_template_and_proceed(review_request:, review:)

    if active? && review_request.present?
      customer = review_request.customer

      if discount_coupon.present?
        review_request_coupon_code = discount_coupon.review_request_coupon_codes.find_by_review_request_id(review_request.id)

        if review_request_coupon_code.present?
          replacement = parse_template(code: review_request_coupon_code.coupon_code)
          review_request.mark_as_with_incentive! if results_in_incentive?
          review.mark_as_with_incentive! if review.present? && results_in_incentive?
        elsif (discount_coupon.send_per_customer? && customer.has_discount_coupon(discount_coupon)) || !discount_coupon.active?
          replacement = ""
        elsif discount_coupon.active_for_review_request?(review_request)
          coupon_code = discount_coupon.coupon_code
          review_request_coupon_code = ReviewRequestCouponCode.create(review_request: review_request, coupon_code: coupon_code)
          discount_coupon.increment!(:issue_count)
          increment!(:usage_count)
          replacement = parse_template(code: coupon_code)
          review_request.mark_as_with_incentive! if results_in_incentive?
          review.mark_as_with_incentive! if review.present? && results_in_incentive?
        else
          replacement = ""
        end
      else
        replacement = parse_template
      end
    else
      replacement = ""
    end

    replacement
  end

  def usage_limit
    discount_coupons.visible.first&.limit
  end

  def active?
    starts_at <= DateTime.current && (ends_at.nil? || ends_at >= DateTime.current) && (discount_coupon.blank? || discount_coupon.active?)
  end

  def starts_at_text
    starts_at.strftime(DateFormat.string_format(store.settings(:global).date_format))
  end

  def ends_at_text
    ends_at&.strftime(DateFormat.string_format(store.settings(:global).date_format)) || "This promotion doesn't have the end date"
  end

  def remove_from_all_templates
    review_settings = store.settings(:reviews)
    review_settings_attributes = {}

    [:review_request_mail_body, :repeat_review_request_mail_body, :comment_mail_body, :positive_review_followup_mail_body,
     :critical_review_followup_mail_body, :facebook_post_template, :tweet_template].each do |template_name|
       template = review_settings.send(template_name)
       updated_template = template.gsub("[#{name}]", '') if template.present?

       review_settings_attributes[template_name] = updated_template
    end

    store.settings(:reviews).update_attributes(review_settings_attributes)
  end

   def results_in_incentive?
     incentive || store.settings(:promotions).mark_reviews_with_incentive.to_b
   end

  private

  def must_start_before_end
    if starts_at && ends_at
      errors.add(:ends_at, '^End date must be greater than start date') if starts_at > ends_at
    end
  end

end
