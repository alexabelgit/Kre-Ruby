class AddTitleToImportedReviews < ActiveRecord::Migration[5.2]
  def change
    add_column :imported_reviews, :title, :string
  end
end
