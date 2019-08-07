module Maintenance
  class ProductSkuMatchingService
    attr_reader :store_from, :store_to

    def initialize(store_from, store_to)
      @store_from = store_from
      @store_to = store_to
    end

    def matching_products
      query = <<SQL
      SELECT store_from_product_id, store_to_product_id
      FROM (
        SELECT id_from_provider as store_from_product_id, skus as source_store_product_skus
        FROM products
        WHERE products.store_id = #{store_from.id}
      ) AS source_store
      INNER JOIN (
        SELECT id_from_provider as store_to_product_id, skus as target_store_product_skus
        FROM products
        WHERE products.store_id = #{store_to.id}
      ) as target_store
      ON source_store.source_store_product_skus && target_store.target_store_product_skus
SQL

      results = Product.connection.execute query
      results.map { |row| OpenStruct.new row}
    end
  end
end