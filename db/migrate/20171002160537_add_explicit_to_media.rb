class AddExplicitToMedia < ActiveRecord::Migration[5.0]
  def change
    add_column :media, :explicit, :boolean, null: false, default: false
  end
end
