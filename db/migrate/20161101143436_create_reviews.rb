class CreateReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :reviews do |t|
      t.references :order_product, null: false
      t.integer :status, null: false, default: 0
      t.integer :rating
      t.text :feedback
      t.timestamps
    end
    add_index :reviews, :order_product_id, unique: true, name: 'index_reviews_unique_on_order_product_id'
  end
end