class AddUniqueIndexesToSocialPosts < ActiveRecord::Migration[5.0]
  def change
    add_index :social_posts, [:provider, :uid], unique: true
  end
end
