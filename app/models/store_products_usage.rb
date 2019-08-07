class StoreProductsUsage < ApplicationRecord
  belongs_to :store

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  rescue ActiveRecord::StatementInvalid
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def readonly?
    true
  end
end