class UpdateStoreSubscriptionUsagesToVersion5 < ActiveRecord::Migration[5.2]
  def change
    update_view :store_subscription_usages, version: 5, revert_to_version: 4, materialized: true
  end
end
