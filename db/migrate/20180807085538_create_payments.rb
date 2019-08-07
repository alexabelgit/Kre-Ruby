class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments do |t|
      t.string :id_from_provider, index: true
      t.integer :amount
      t.string :payment_type, index: true
      t.text :description
      t.datetime :payment_made_at, index: true
      t.references :subscription, index: true
      t.references :store, index: true

      t.timestamps
    end
  end
end
