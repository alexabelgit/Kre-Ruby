class UpdateStoreSubscriptionUsagesToVersion3 < ActiveRecord::Migration[5.2]
  def change
    update_view :store_subscription_usages, version: 3, revert_to_version: 2, materialized: true
  end
end
