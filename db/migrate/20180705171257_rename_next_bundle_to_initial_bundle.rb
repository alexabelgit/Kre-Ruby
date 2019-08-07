class RenameNextBundleToInitialBundle < ActiveRecord::Migration[5.1]
  def change
    rename_column :subscriptions, :next_bundle_id, :initial_bundle_id
  end
end
