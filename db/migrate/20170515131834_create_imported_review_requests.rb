class CreateImportedReviewRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :imported_review_requests do |t|

      t.references :customer, null: false
      t.datetime :scheduled_for, null: false
      t.boolean :marked_for_deletion, null: false, default: false

      t.timestamps
    end
  end
end
