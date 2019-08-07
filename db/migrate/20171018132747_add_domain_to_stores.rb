class AddDomainToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :domain, :string
    add_index :stores, :domain, unique: true
  end
end
