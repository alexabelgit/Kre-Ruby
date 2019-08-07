class CreateStoreSummaries < ActiveRecord::Migration[5.2]
  def change
    create_view :store_summaries
  end
end
