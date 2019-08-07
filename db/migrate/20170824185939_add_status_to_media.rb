class AddStatusToMedia < ActiveRecord::Migration[5.0]
  def change
    add_column :media, :status, :integer, null: false, default: 0
  end
end
