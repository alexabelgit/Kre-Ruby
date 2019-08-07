class AddSyncErrorsToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :last_sync_error, :string
    rename_column :stores, :api_unauthorized_access_at, :last_sync_error_at
  end
end
