class AddVerificationToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :verification, :integer, null: false, default: 0
  end
end
