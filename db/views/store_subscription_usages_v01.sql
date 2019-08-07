SELECT
	stores.id AS store_id,
	MAX ( "plans".requests_limit ) AS requests_limit,
	( MAX ( subscriptions.next_billing_at ) - INTERVAL '1 month' ) AS cycle_start,
	MAX ( subscriptions.next_billing_at ) AS cycle_end,
	COUNT ( orders.id ) AS orders_amount 
  FROM
	    stores
      INNER JOIN bundles ON bundles.store_id = stores.id
      INNER JOIN bundle_items ON bundle_items.bundle_id = bundles.id
      INNER JOIN "plans" ON bundle_items.price_entry_id = "plans".id AND bundle_items.price_entry_type = 'Plan'
      INNER JOIN subscriptions ON subscriptions.bundle_id = bundles.id
      INNER JOIN customers ON customers.store_id = stores.id
      INNER JOIN orders ON orders.customer_id = customers.id
 WHERE
	subscriptions.STATE = 3 AND orders.created_at BETWEEN ( subscriptions.next_billing_at - INTERVAL '1 month' ) AND subscriptions.next_billing_at
GROUP BY stores.id
