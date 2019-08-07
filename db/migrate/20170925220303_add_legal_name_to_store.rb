class AddLegalNameToStore < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :legal_name, :string
  end
end
