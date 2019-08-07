class AddSyncedImageBackupToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :synced_image_backup, :string, default: nil
  end
end
