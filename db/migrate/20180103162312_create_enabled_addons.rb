class CreateEnabledAddons < ActiveRecord::Migration[5.0]
  def change
    create_view :enabled_addons, materialized: true
    add_index :enabled_addons, :store_id
  end
end
