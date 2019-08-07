class CreateMedia < ActiveRecord::Migration[5.0]
  def change
    create_table :media do |t|

      t.integer :mediable_id, null: false
      t.string  :mediable_type, null: false

      t.integer :media_type, null: false, default: 0
      t.string  :file

      t.timestamps
    end

    remove_column :reviews, :image
  end
end
