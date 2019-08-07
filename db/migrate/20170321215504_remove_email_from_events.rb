class RemoveEmailFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :email_events, :email
  end
end
