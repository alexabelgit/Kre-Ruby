class CreateBundles < ActiveRecord::Migration[5.0]
  def change
    create_table :bundles do |t|
      t.references :store, index: true, null: false
      t.integer :total_cost

      t.timestamps
    end
  end
end
