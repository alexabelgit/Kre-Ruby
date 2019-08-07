class AddSuppressedToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :suppressed, :boolean, null: false, default: false
  end
end
