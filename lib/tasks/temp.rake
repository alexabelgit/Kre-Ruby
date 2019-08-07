# temporary tasks for maintenance or migration

namespace :tmp do
  task set_last_synced_at_dates: :environment do
    Product.connection.execute 'UPDATE products SET last_synced_at = updated_at, image_last_synced_at = updated_at;'
    Order.connection.execute 'UPDATE orders SET last_synced_at = updated_at;'
  end

  task migrate_to_products: :environment do
    require_relative "#{Rails.root}/db/seeds/billing.rb"
    SeedBilling.new.setup_migration_plans

    Subscriptions::DoMigration.run
  end
end
