class CreatePaymentMethods < ActiveRecord::Migration[5.1]
  def change
    create_table :payment_methods do |t|
      t.string :id_from_provider, index: true
      t.string :customer_id, index: true
      t.string :processing_platform
      t.string :payment_type
      t.string :card_type
      t.string :masked_number
      t.integer :expiry_month
      t.integer :expiry_year
      t.references :user, index: true

      t.timestamps
    end

    add_column :subscriptions, :payment_method_id, :integer, index: true
  end
end
