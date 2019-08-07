class AddOtherReasonToAbuseReports < ActiveRecord::Migration[5.0]
  def change
    add_column :abuse_reports, :additional_info, :string
  end
end
