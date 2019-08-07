class AddSgMessageIdToEmails < ActiveRecord::Migration[5.0]
  def change
    add_column :emails, :sg_message_id, :string
  end
end
