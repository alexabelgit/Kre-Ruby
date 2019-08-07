class NullableEmailInCustomers < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:customers, :email, true)
  end
end
