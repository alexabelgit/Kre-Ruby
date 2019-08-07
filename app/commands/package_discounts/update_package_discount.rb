module PackageDiscounts
  class UpdatePackageDiscount < ApplicationCommand
    object :package_discount

    record :ecommerce_platform
    integer :addons_count
    integer :discount_percents

    string :chargebee_id, default: nil

    def execute
      if package_discount.bundles.not_draft.present?
        errors.add(:package_discount, 'already applied to some bundles')
        return package_discount
      end

      package_discount.ecommerce_platform = ecommerce_platform if ecommerce_platform
      package_discount.addons_count = addons_count if addons_count?
      package_discount.discount_percents = discount_percents if discount_percents?
      package_discount.chargebee_id = chargebee_id if chargebee_id?

      unless package_discount.save
        errors.merge!(package_discount.errors)
      end

      package_discount
    end
  end
end
