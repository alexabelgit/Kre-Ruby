class GenericVotes < ActiveRecord::Migration[5.0]
  def change

    add_column :votes, :votable_id, :integer
    add_column :votes, :votable_type, :string

    Vote.all.each do |vote|
      vote.votable = Review.find_by_id(vote.review_id)
      vote.save
    end

    remove_column :votes, :review_id

    change_column_null(:votes, :votable_id, false)
    change_column_null(:votes, :votable_type, false)

  end
end