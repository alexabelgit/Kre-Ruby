class CreateEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :emails do |t|

      t.integer :sendable_id, null: false
      t.string :sendable_type, null: false

      t.text :'smtp-id'

      t.timestamps
    end
  end
end