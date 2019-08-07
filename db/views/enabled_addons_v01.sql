SELECT stores.id AS store_id, addon_prices.addon_id as enabled_addon_id
FROM stores
INNER JOIN bundles ON bundles.store_id = stores.id
INNER JOIN bundle_items ON bundle_items.bundle_id = bundles.id
INNER JOIN addon_prices ON addon_prices.id = bundle_items.addon_price_id
INNER JOIN addons ON addons.id = addon_prices.addon_id
WHERE bundles.state = 2 -- active state
