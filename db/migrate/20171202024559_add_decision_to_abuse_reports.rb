class AddDecisionToAbuseReports < ActiveRecord::Migration[5.0]
  def change
    add_column :abuse_reports, :decision, :integer, null: false, default: 0
  end
end
