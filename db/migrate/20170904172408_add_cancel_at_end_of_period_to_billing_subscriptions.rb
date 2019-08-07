class AddCancelAtEndOfPeriodToBillingSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :billing_subscriptions, :cancel_at_end_of_period, :boolean, null: false, default: true
    add_column :billing_subscriptions, :current_period_ends_at, :datetime
    add_column :billing_subscriptions, :product_price_in_cents, :integer, null: false, default: 0
    BillingSubscription.reset_column_information

    BillingSubscription.all.each do |billing_subscription|
      subscription = billing_subscription.from_api
      billing_subscription.update_attributes(cancel_at_end_of_period: subscription.cancel_at_end_of_period,
                                             current_period_ends_at:  subscription.current_period_ends_at,
                                             product_price_in_cents:  subscription.product_price_in_cents)
    end
  end
end
