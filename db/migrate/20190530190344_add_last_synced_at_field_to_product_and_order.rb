class AddLastSyncedAtFieldToProductAndOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :last_synced_at, :datetime
    add_column :products, :image_last_synced_at, :datetime
    add_column :orders, :last_synced_at, :datetime
  end
end
