class ChangePlanNameToJustName < ActiveRecord::Migration[5.1]
  def change
    rename_column :plans, :plan_name, :name
    add_index :plans, :name
  end
end
