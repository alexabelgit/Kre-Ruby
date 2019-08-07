SELECT
	stores.id AS store_id,
	(MAX ( "plans".requests_limit ) + COALESCE(MAX(gifted_orders.amount), 0)) AS requests_limit,
( MAX ( subscriptions.next_billing_at ) - INTERVAL '1 month' ) AS cycle_start,
	MAX ( subscriptions.next_billing_at ) AS cycle_end,
	COUNT ( DISTINCT orders.id ) AS orders_amount 
  FROM
	    stores
      INNER JOIN bundles ON bundles.store_id = stores.id
			LEFT OUTER JOIN orders_gifts ON orders_gifts.bundle_id = bundles.id
      INNER JOIN bundle_items ON bundle_items.bundle_id = bundles.id
      INNER JOIN "plans" ON bundle_items.price_entry_id = "plans".id AND bundle_items.price_entry_type = 'Plan'
      INNER JOIN subscriptions ON subscriptions.bundle_id = bundles.id OR subscriptions.initial_bundle_id = bundles.id
			INNER JOIN customers ON customers.store_id = stores.id
      INNER JOIN orders ON orders.customer_id = customers.id
			LEFT OUTER JOIN (
			SELECT bundles.id AS bundle_id, SUM(orders_gifts.amount) AS amount FROM orders_gifts
			INNER JOIN bundles ON orders_gifts.bundle_id = bundles.id
			INNER JOIN subscriptions ON subscriptions.bundle_id = bundles.id OR subscriptions.initial_bundle_id = bundles.id
			WHERE 
			subscriptions.STATE = 3 AND
			orders_gifts.applied_at BETWEEN (subscriptions.next_billing_at - INTERVAL '1 month') AND subscriptions.next_billing_at
			GROUP BY bundles.id
			) gifted_orders ON bundles.id = gifted_orders.bundle_id
 WHERE
	subscriptions.STATE = 3 AND orders.order_date > stores.created_at
	AND orders.created_at BETWEEN ( subscriptions.next_billing_at - INTERVAL '1 month' ) AND subscriptions.next_billing_at
GROUP BY stores.id
