class AddTrialPeriodsToStore < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :trial_started_at, :datetime, index: true
    add_column :stores, :trial_ends_at, :datetime, index: true
  end
end
