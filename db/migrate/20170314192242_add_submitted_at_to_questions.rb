class AddSubmittedAtToQuestions < ActiveRecord::Migration[5.0]
  def change

    add_column :questions, :submitted_at, :datetime
    Question.all.each do |question|
      question.update_attributes(submitted_at: question.created_at)
    end
    change_column_null(:questions, :submitted_at, false)

  end
end
