module DiscountCoupons
  class UpdateDiscountCoupon < ApplicationCommand
    object    :discount_coupon

    string    :name,                default: nil
    symbol    :code_type,           default: nil
    date_time :valid_from,          default: nil
    date_time :valid_until,         default: nil
    integer   :discount_amount,     default: nil
    string    :discount_type,       default: nil
    symbol    :discount_sequence,   default: nil
    integer   :limit,               default: nil
    symbol    :send_per,            default: nil
    symbol    :status,              default: nil

    file      :file,                default: nil
    string    :code,                default: nil

    def execute
      ActiveRecord::Base.transaction do
        attributes               = inputs.except(:discount_coupon, :file, :code).compact
        if status.nil?
          attributes[:limit]       = nil if limit.nil?
          attributes[:valid_until] = nil if valid_until.nil?
        end

        if file.present? && code_type == :unique
          csv = Array.csv_to_array(file)
          if csv
            if csv.empty?
              self.errors.add(:csv, 'The file is empty')
            else
              csv.uniq.each do |c|
                @discount_coupon.coupon_codes << CouponCode.new(code: c[c.keys.first]) unless @discount_coupon.coupon_codes.where(code: c[c.keys.first]).any?
              end
              attributes[:limit] = @discount_coupon.coupon_codes.size
            end
          else
            self.errors.add(:csv, 'Invalid CSV format')
          end
        elsif code.present? && code_type == :reusable
          coupon_code = CouponCode.new(code: code)
          @discount_coupon.coupon_codes << coupon_code
          @discount_coupon.make_code_current(coupon_code)
        end
        raise ActiveRecord::Rollback unless discount_coupon.update_attributes(attributes)
      end
      errors.merge!(discount_coupon.errors)
      discount_coupon.errors.clear
      discount_coupon.errors.merge!(errors)

      discount_coupon
    end
  end
end
