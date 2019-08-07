class RemoveFileFromMedia < ActiveRecord::Migration[5.0]
  def change
    remove_column :media, :file
  end
end
