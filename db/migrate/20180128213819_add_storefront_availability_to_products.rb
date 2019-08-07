class AddStorefrontAvailabilityToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :storefront_availability, :integer, null: false, default: 0
  end
end
