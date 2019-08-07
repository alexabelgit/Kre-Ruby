class ChangeImportedReviews < ActiveRecord::Migration[5.2]
  def change
    change_column :imported_reviews, :product_id, :integer, null: true
  end
end
