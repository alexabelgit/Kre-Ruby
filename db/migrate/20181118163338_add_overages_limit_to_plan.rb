class AddOveragesLimitToPlan < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :overages_limit_in_cents, :integer
  end
end
