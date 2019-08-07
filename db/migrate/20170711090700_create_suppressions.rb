class CreateSuppressions < ActiveRecord::Migration[5.0]
  def change
    create_table :suppressions do |t|
      t.integer    :source
      t.references :customer
      t.references :store
      t.string     :email

      t.timestamps
    end
  end
end
