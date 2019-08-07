module PackageDiscounts
  class CreatePackageDiscount < ApplicationCommand
    record :ecommerce_platform
    integer :addons_count
    integer :discount_percents

    string :chargebee_id, default: nil

    def execute
      new_package_discount = PackageDiscount.new inputs

      if new_package_discount.save
        deprecate_old_package_discount new_package_discount
      else
        errors.merge!(new_package_discount.errors)
      end
      new_package_discount
    end

    private

    def deprecate_old_package_discount(new_discount)
      filters = {
        ecommerce_platform: new_discount.ecommerce_platform,
        addons_count: new_discount.addons_count
      }

      old_discount = PackageDiscount.where.not(id: new_discount).find_by filters
      return if old_discount.blank?

      old_discount.deprecate!
    end
  end
end
