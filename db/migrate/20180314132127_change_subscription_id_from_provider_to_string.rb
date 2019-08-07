class ChangeSubscriptionIdFromProviderToString < ActiveRecord::Migration[5.1]
  def up
    change_column :subscriptions, :id_from_provider, :string
  end

  def down
    change_column :subscriptions, :id_from_provider, :integer
  end
end
