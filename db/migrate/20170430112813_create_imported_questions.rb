class CreateImportedQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :imported_questions do |t|

      t.references :product, null: false
      t.references :customer, null: false

      t.integer :status, null: false, default: 0

      t.boolean :marked_for_deletion, null: false, default: false
      t.boolean :verified, null: false, default: false

      t.text :body
      t.text :answer

      t.datetime :submitted_at, null: false

      t.timestamps
    end
  end
end
