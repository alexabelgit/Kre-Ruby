class AddPricingModelToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :pricing_model, :pricing_model, index: true, default: 'products'

    create_table :suggested_plans do |t|
      t.references :store, index: true
      t.references :plan, index: true
      t.integer :priority

      t.timestamps
    end
  end
end
