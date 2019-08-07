class AddPerformanceIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :review_requests, :customer_id
    add_index :emails, '"smtp-id"'
  end
end
