class AddGiftedToSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :gifted, :boolean, default: false
  end
end
