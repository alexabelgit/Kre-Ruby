class CreateFlags < ActiveRecord::Migration[5.0]
  def change
    create_table :flags do |t|
      t.references :review, null: false
      t.timestamps
    end
  end
end