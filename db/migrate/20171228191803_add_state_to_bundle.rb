class AddStateToBundle < ActiveRecord::Migration[5.0]
  def change
    add_column :bundles, :state, :integer, index: true
  end
end
