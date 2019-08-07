class AddExtensionAndIsSecretToPlan < ActiveRecord::Migration[5.1]
  def change
    add_column :plans, :extension_price_in_cents, :integer
    add_column :plans, :extended_requests_limit,  :integer
    add_column :plans, :is_secret,                :boolean, default: false
  end
end
