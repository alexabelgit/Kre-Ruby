class AddPlanEmailsSuspendedToSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :plan_emails_suspended, :boolean, default: false
  end
end
