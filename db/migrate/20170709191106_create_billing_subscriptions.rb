class CreateBillingSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :billing_subscriptions do |t|
      t.references :store, null: false
      t.integer :plan, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :id_from_provider, null: false
      t.timestamps
    end

    add_index :billing_subscriptions, :id_from_provider, unique: true
  end
end
