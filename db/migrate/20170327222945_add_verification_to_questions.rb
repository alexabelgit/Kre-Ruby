class AddVerificationToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :questions, :verification, :integer, null: false, default: 0
  end
end
