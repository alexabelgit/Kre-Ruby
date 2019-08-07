class UpdateEnabledAddonsToVersion2 < ActiveRecord::Migration[5.0]
  def change
    add_column :bundle_items, :price_entry_id, :integer, index: true
    add_column :bundle_items, :price_entry_type, :string

    update_view :enabled_addons, version: 2, revert_to_version: 1, materialized: true

    remove_column :bundle_items, :addon_price_id, :integer
    remove_column :bundle_items, :price_in_cents
  end
end
