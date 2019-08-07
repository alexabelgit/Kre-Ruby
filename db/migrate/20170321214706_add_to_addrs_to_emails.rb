class AddToAddrsToEmails < ActiveRecord::Migration[5.0]
  def change
    add_column :emails, :address, :string
  end
end
