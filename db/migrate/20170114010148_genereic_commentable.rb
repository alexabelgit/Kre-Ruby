class GenereicCommentable < ActiveRecord::Migration[5.0]
  def change

    add_column :comments, :commentable_id, :integer
    add_column :comments, :commentable_type, :string

    Comment.all.each do |comment|

      comment.commentable = Review.find_by_id(comment.review_id)
      comment.save

    end

    remove_column :comments, :review_id

    change_column_null(:comments, :commentable_id, false)
    change_column_null(:comments, :commentable_type, false)

  end
end