module PackageDiscounts
  class DestroyPackageDiscount < ApplicationCommand
    record :package_discount

    def execute
      if package_discount.applied_discounts.present?
        errors.add(:package_discount, 'has applied discounts and could only be deprecated')
        package_discount
      else
        package_discount.destroy
      end
    end
  end
end
