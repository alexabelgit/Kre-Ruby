class RemoveDraftReviewHashid < ActiveRecord::Migration[5.0]
  def change
    remove_column :order_products, :draft_review_hashid
  end
end
