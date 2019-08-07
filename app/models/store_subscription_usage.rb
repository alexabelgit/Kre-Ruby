class StoreSubscriptionUsage < ApplicationRecord
  belongs_to :store

  WARNING_PERCENT_START = 80
  WARNING_PERCENT_END = 100

  scope :exceeding_limit, -> do
    where('100.0 * orders_amount / orders_limit <@ numrange(:start, :end)',
          start: WARNING_PERCENT_START, end: WARNING_PERCENT_END)
  end

  scope :exceeded_limit, -> do
    where('100.0 * orders_amount / orders_limit >= ?', WARNING_PERCENT_END)
  end

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  rescue ActiveRecord::StatementInvalid
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def readonly?
    true
  end
end