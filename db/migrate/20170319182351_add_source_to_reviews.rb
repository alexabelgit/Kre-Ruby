class AddSourceToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :source, :integer, null: false, default: 0
  end
end