class AddDisplayNameToComment < ActiveRecord::Migration[5.0]
  def change
    add_column :comments, :display_name, :string
  end
end
