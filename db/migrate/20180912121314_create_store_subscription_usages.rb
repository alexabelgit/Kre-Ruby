class CreateStoreSubscriptionUsages < ActiveRecord::Migration[5.2]
  def change
    create_view :store_subscription_usages, materialized: true

    add_index :store_subscription_usages, :store_id, unique: true
  end
end
