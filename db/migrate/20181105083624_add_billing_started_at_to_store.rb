class AddBillingStartedAtToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :billing_started_at, :datetime
  end
end
