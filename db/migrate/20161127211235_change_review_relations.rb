class ChangeReviewRelations < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:reviews, :order_product_id, true)

    add_reference :reviews, :product, null: true

    Review.all.each do |review|
      review.update_attributes(product_id: review.order_product.product.id)
    end

    change_column_null(:reviews, :product_id, false)
  end
end