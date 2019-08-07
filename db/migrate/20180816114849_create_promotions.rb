class CreatePromotions < ActiveRecord::Migration[5.1]
  def change
    create_table :promotions do |t|
      t.string     :name, unique: true
      t.text       :template
      t.datetime   :starts_at
      t.datetime   :ends_at
      t.references :store

      t.timestamps
    end
  end
end
