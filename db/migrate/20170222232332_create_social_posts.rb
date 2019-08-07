class CreateSocialPosts < ActiveRecord::Migration[5.0]
  def change
    create_table :social_posts do |t|
      t.integer :postable_id, null: false
      t.string :postable_type, null: false
      t.integer :provider, null: false
      t.string :uid, null: false
      t.timestamps
    end
  end
end
