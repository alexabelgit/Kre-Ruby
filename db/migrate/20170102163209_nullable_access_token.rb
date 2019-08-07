class NullableAccessToken < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:stores, :access_token, true)
  end
end