#!/bin/bash

echo "Running Release Tasks"

if [ "$RELEASE_RUN_MIGRATIONS" == true ]; then
    echo "Running db:migrate"
    bundle exec rails db:migrate
fi

if [ "$RELEASE_DUMP_LOCALES" == true ]; then
    echo "Dumping locales from Tolk DB"
    bundle exec rake tolk:dump_all
fi

if [ "$RELEASE_CLEAR_CACHE" == true ]; then
    echo "Cleaning cache"
    bundle exec rails r "Rails.cache.clear"
fi

if [ "$RELEASE_SYNC_SHOPIFY_ASSETS" == true ]; then
    echo "Syncing Shopify assets"
    bundle exec rake shopify:sync_store_assets
fi

echo "Release tasks finished"
