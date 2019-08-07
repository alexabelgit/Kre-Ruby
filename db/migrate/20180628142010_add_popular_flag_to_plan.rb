class AddPopularFlagToPlan < ActiveRecord::Migration[5.1]
  def change
    add_column :plans, :popular, :boolean, default: false
  end
end
