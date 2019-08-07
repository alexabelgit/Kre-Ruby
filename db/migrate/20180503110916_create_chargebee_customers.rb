class CreateChargebeeCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :chargebee_customers do |t|
      t.string :id_from_provider, null: false
      t.string :email
      t.string :first_name
      t.string :last_name

      t.references :store, index: true

      t.timestamps
    end
  end
end
