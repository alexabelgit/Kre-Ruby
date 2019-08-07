class ChangeSubscriptionIdFromProviderType < ActiveRecord::Migration[5.1]
  def up
    change_column :subscriptions, :id_from_provider, :text
    add_index :subscriptions, :id_from_provider, unique: true
  end

  def down
    # do not rollback id_from_provider type change since somce ids could not be converted back to integer
    remove_index :subscriptions, :id_from_provider
  end
end
