class ChangeSendableToEmailableinEmails < ActiveRecord::Migration[5.0]
  def change
    change_table :emails do |t|
      t.rename :sendable_id,   :emailable_id
      t.rename :sendable_type, :emailable_type
    end
  end
end
