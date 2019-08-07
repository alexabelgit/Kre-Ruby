class AddCustomerToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_reference :questions, :customer
  end
end
