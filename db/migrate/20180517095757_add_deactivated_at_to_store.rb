class AddDeactivatedAtToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :deactivated_at, :datetime, index: true
  end
end
