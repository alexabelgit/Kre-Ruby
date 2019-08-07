class AddDueInvoicesToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :total_due, :integer, default: 0, index: true
    add_column :subscriptions, :due_invoices_count, :integer
    add_column :subscriptions, :due_since, :datetime
  end
end
