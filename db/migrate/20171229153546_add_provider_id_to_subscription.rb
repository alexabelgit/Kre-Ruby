class AddProviderIdToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :id_from_provider, :integer, index: true
  end
end
