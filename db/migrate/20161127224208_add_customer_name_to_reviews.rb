class AddCustomerNameToReviews < ActiveRecord::Migration[5.0]
  def change

    add_column :reviews, :customer_name, :string, null: true

    Review.all.each do |review|
      review.update_attributes(customer_name: review.customer.name)
    end

    change_column_null(:reviews, :customer_name, false)

  end
end