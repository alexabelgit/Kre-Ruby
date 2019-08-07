class AddApiUnauthorizedAccessAtToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :api_unauthorized_access_at, :datetime
  end
end
