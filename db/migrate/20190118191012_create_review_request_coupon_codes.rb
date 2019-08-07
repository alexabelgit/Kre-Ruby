class CreateReviewRequestCouponCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :review_request_coupon_codes do |t|
      t.references :coupon_code
      t.references :review_request

      t.timestamps
    end
  end
end
