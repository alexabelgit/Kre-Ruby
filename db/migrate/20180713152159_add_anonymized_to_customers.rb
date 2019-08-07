class AddAnonymizedToCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :customers, :anonymized, :boolean, null: false, default: false
  end
end
