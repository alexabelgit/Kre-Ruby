class CreateBackReviewRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :review_requests do |t|
      t.references :order, null: false
      t.datetime :scheduled_for
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end