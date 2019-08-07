class CreateImportedReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :imported_reviews do |t|

      t.references :product, null: false
      t.references :customer, null: false

      t.integer :status, null: false, default: 0

      t.boolean :marked_for_deletion, null: false, default: false
      t.boolean :verified, null: false, default: false

      t.integer :rating
      t.text :feedback
      t.text :comment

      t.datetime :review_date

      t.timestamps
    end
  end
end
