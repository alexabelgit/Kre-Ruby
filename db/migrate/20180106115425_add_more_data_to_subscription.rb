class AddMoreDataToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :processing_platform, :string, null: false, index: true, default: 'shopify'
    add_column :subscriptions, :activated_on, :datetime, index: true
    add_column :subscriptions, :cancelled_on, :datetime
  end
end
