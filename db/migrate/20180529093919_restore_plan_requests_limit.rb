class RestorePlanRequestsLimit < ActiveRecord::Migration[5.1]
  def change
    add_column :plans, :requests_limit, :integer
  end
end
