class AddNextBundleIdToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :next_bundle_id, :integer, index: true
  end
end
