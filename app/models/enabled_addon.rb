class EnabledAddon < ApplicationRecord
  belongs_to :store, touch: true

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  def readonly?
    true
  end
end
