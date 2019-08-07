class AddFieldsToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :installed_at,   :datetime
    add_column :stores, :uninstalled_at, :datetime
  end
end
