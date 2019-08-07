SELECT stores.id as store_id, COUNT(products.id) AS products_count
FROM stores
INNER JOIN products ON stores.id = products.store_id
WHERE products.suppressed = false AND products.status = 0
GROUP BY stores.id