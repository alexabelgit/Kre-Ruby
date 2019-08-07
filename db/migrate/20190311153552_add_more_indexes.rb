class AddMoreIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :review_reviewables, :reviewable_type
  end
end
