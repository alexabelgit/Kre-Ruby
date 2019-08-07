class CreateAppliedDiscounts < ActiveRecord::Migration[5.0]
  def change
    create_table :applied_discounts do |t|
      t.references :bundle, index: true, null: false
      t.references :package_discount, null: false, index: true

      t.timestamps
    end
  end
end
