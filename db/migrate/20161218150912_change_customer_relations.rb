class ChangeCustomerRelations < ActiveRecord::Migration[5.0]
  def change

    add_reference :reviews, :customer, null: true

    Review.all.each do |review|
      review.update_attributes(customer_id: review.order_product.order.customer.id) if review.order_product_id.present?
    end

    Review.where(customer_id: nil).each do |review|
      review.destroy
    end


    change_column_null(:reviews, :customer_id, false)

    remove_column :reviews, :customer_name

  end
end