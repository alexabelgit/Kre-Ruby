class CreateImportedReviewRequestProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :imported_review_request_products do |t|
      t.references :product, null: false
      t.references :imported_review_request, null: false, index: { name: 'index_imported_request_products_on_request_id' }
      t.timestamps
    end
    add_index :imported_review_request_products, [:imported_review_request_id, :product_id],
              unique: true, name: 'index_unique_imported_review_request_product'
  end
end
