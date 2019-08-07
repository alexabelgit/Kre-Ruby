class UpdateStoreSubscriptionUsagesToVersion4 < ActiveRecord::Migration[5.2]
  def change
    update_view :store_subscription_usages, version: 4, revert_to_version: 3, materialized: true
  end
end
