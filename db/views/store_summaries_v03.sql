SELECT users.email,
       stores.id AS store_id, stores.name AS store_name,
       stores.created_at AS first_installed_at, stores.installed_at AS latest_installed_at,
       CASE WHEN stores.access_token IS NULL THEN 'inactive' ELSE 'active' END AS store_status,
       CASE WHEN stores.status = 1 THEN 'active' ELSE 'inactive' END AS backend_status,
       CASE WHEN stores.storefront_status = 1 THEN 'active' ELSE 'inactive' END AS storefront_status,
       ecommerce_platforms.name AS ecommerce_platform,
       COALESCE(active_plans.plan_name, CASE
                                          WHEN stores.trial_ends_at > NOW() THEN 'Trial'
                                          WHEN stores.trial_ends_at > (NOW() - INTERVAL '5 DAYS') THEN 'Grace period'
                                          ELSE 'Trial ended'
         END) AS plan_name,
       active_plans.price_in_cents AS price_in_cents
FROM users
       LEFT OUTER JOIN stores ON users.id = stores.user_id
       INNER JOIN ecommerce_platforms ON ecommerce_platforms.id = stores.ecommerce_platform_id
       LEFT OUTER JOIN (
    SELECT bundles.store_id AS store_id,
           "plans".name AS plan_name,
           "plans".price_in_cents AS price_in_cents
    FROM bundles
           INNER JOIN bundle_items ON bundles.id = bundle_items.bundle_id
           INNER JOIN "plans" ON "plans".id = bundle_items.price_entry_id AND bundle_items.price_entry_type = 'Plan'
    WHERE bundles."state" = 2 )
    as active_plans ON active_plans.store_id = stores.id
ORDER BY stores.id ASC