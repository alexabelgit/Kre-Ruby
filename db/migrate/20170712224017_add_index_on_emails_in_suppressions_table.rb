class AddIndexOnEmailsInSuppressionsTable < ActiveRecord::Migration[5.0]
  def change
    add_index :suppressions, [:email, :store_id, :source]
  end
end
