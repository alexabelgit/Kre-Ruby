class AddHelpfulIdToEmails < ActiveRecord::Migration[5.0]
  def change
    Email.destroy_all
    add_column :emails, :helpful_id, :string, null: false
    add_index :emails, :helpful_id, unique: true
  end
end
