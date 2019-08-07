# How improve Shopify Sync
## Metafields
* Store information of last updated metafield locally ( db or redis )
* Use JSON for metafields, store all information in one field, add last_updated_at
* Separate metafields preparation and API calls themselves
* Priority for metafields sync - recently active stores, most popular products, products with positive rating ordered by amount of reviews/qa
* Global metafields also to JSON. Proper algorithm to find diff between old JSON and new JSON

## General API interaction
* Add leaky-bucket algorithm support to ShopifyApiThrottler
* Reduce memory footprint by storing fetched objects in Redis instead of memory
* Cache fetched Shopify objects for certain time

## Other
* Address issue with hashids as well ( probably just update and resync would be enough )

