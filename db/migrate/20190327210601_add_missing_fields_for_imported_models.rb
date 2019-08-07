class AddMissingFieldsForImportedModels < ActiveRecord::Migration[5.2]
  def change
    add_column :imported_reviews, :votes_count, :integer
    add_column :imported_questions, :votes_count, :integer
  end
end
