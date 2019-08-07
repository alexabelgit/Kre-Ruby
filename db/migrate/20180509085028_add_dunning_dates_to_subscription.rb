class AddDunningDatesToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :dunning_start_date, :datetime
    add_column :subscriptions, :dunning_end_date, :datetime
    add_column :subscriptions, :cancellation_reason, :string
  end
end
