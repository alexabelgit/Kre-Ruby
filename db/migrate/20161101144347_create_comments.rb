class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.references :review, null: false
      t.references :user, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end