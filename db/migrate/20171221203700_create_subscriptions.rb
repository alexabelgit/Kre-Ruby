class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.integer :state
      t.references :bundle, null: false, index: true
      t.datetime :last_payment_at
      t.datetime :expired_at
      t.string :payment_error

      t.timestamps
    end
  end
end
