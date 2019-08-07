class CreateAddOns < ActiveRecord::Migration[5.0]
  def change
    create_table :add_ons do |t|
      t.references :billing_subscription, null: false
      t.integer :status, null: false, default: 0
      t.integer :kind, null: false
      t.timestamps
    end
  end
end
