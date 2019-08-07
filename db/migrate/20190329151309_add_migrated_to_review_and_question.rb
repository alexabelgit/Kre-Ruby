class AddMigratedToReviewAndQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :reviews, :migrated, :boolean, default: false
    add_column :questions, :migrated, :boolean, default: false
  end
end
