class ChangeReviewRelationsThroughRequestsPart1 < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:orders, :id_from_provider, true)

    add_column :order_products, :draft_review_hashid, :string

    # Review.where.not(order_product_id: nil).each do |review|
    #
    #   review_request = ReviewRequest.find_by_order_id(review.order_product.order_id)
    #   review_request = ReviewRequest.create(order_id: review.order_product.order_id, scheduled_for: nil) unless review_request.present?
    #
    #   if Review.statuses[review.status] == 0
    #     review.order_product.update_attributes(draft_review_hashid: review.hashid)
    #     review_request.update_attributes(status: 'pending')
    #     review.destroy
    #   else
    #     review.update_attributes(review_request_id: review_request.id)
    #   end
    # end
    #
    # Review.where.not(review_request_id: nil).each do |review|
    #   if review.review_request.present?
    #     status = 'complete'
    #     review.review_request.order_products.where.not(id: review.order_product_id).each do |order_product|
    #       unless order_product.review.present?
    #         status = 'incomplete'
    #       end
    #     end
    #     review.review_request.update_attributes(status: status)
    #   end
    # end
    #
    # Review.where(order_product_id: nil).each do |review|
    #   order = Order.create(customer: Customer.find_by_id(review.customer_id))
    #   order_product = OrderProduct.create(order: order, product: Product.find_by_id(review.product_id))
    #   review.update_attributes(order_product_id: order_product.id)
    #   review.save
    # end
    #
    # Review.where(status: 1).update_all(status: 0)
    # Review.where(status: 2).update_all(status: 1)
    # Review.where(status: 3).update_all(status: 2)


    change_column_null(:reviews, :order_product_id, false)

    remove_column :reviews, :customer_id
    remove_column :reviews, :product_id
  end
end
