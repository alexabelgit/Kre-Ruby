class EvenMoreIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :bundle_items, [:price_entry_id, :price_entry_type]
    add_index :comments, [:commentable_id, :commentable_type]
    add_index :emails, [:emailable_id, :emailable_type]
    add_index :flags, [:flaggable_id, :flaggable_type]
    add_index :payment_methods, :chargebee_customer_id
    add_index :social_posts, [:postable_id, :postable_type]
    add_index :stores, :ecommerce_platform_id
    add_index :subscriptions, :chargebee_customer_id
    add_index :subscriptions, :initial_bundle_id
    add_index :votes, [:votable_id, :votable_type]
    remove_index :media, :mediable_id
    add_index :media, [:mediable_id, :mediable_type]
  end
end
