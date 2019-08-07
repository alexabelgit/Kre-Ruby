class CreateReviewReviewables < ActiveRecord::Migration[5.2]
  def change
    create_table :review_reviewables do |t|
      t.references :review
      t.integer    :reviewable_id, null: false
      t.string     :reviewable_type, null: false
      t.timestamps
    end
  end
end
