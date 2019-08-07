module Promotions
  class UpdatePromotion < ApplicationCommand
    string    :discount_coupon_id
    object    :store
    object    :promotion

    string    :name
    string    :template
    date_time :starts_at
    date_time :ends_at,   default: nil
    boolean   :incentive

    def execute
      ActiveRecord::Base.transaction do
        attributes = inputs.except(:discount_coupon_id, :store, :promotion)
        raise ActiveRecord::Rollback unless promotion.promotion_discount_coupons.destroy_all
        discount_coupon = store.discount_coupons.visible.find_by_hashid(discount_coupon_id)
        raise ActiveRecord::Rollback unless promotion.promotion_discount_coupons << PromotionDiscountCoupon.new(discount_coupon: discount_coupon)
        raise ActiveRecord::Rollback unless promotion.update_attributes(attributes)
      end
      errors.merge!(promotion.errors)
      promotion.errors.clear
      promotion.errors.merge!(errors)

      promotion
    end
  end
end
