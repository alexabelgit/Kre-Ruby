class UpdateEnabledAddonsToVersion3 < ActiveRecord::Migration[5.0]
  def change
    update_view :enabled_addons, version: 3, revert_to_version: 2, materialized: true
    add_index :enabled_addons, [:store_id, :enabled_addon_id], unique: true
  end
end
