class CreateQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :questions do |t|
      t.references :product, null: false
      t.integer :status, null: false, default: 0
      t.text :body
      t.timestamps
    end
  end
end