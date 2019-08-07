class CreateTransactionItems < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_items do |t|
      t.references :order
      t.references :review_request
      t.references :customer
      t.integer    :reviewable_id, null: false
      t.string     :reviewable_type, null: false
      t.timestamps
    end
  end
end
