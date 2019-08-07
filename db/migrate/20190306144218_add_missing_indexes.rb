class AddMissingIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :email_events, :email_id
    add_index :review_reviewables, [:reviewable_id, :reviewable_type]
    add_index :reviews, :customer_id
    add_index :reviews, :transaction_item_id
    add_index :transaction_items, [:reviewable_id, :reviewable_type]
  end
end
