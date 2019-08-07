namespace :stores do
  desc "Migrates old provider enum to ecommerce platform association"
  task migrate_provider_to_ecommerce_platform: :environment do
    old_providers = { 0 => 'ecwid', 1 => 'shopify', 2 => 'custom' }
    Store.all.each do |store|
      provider_enum_value = store['provider']
      name = old_providers[provider_enum_value]

      platform = EcommercePlatform.send(name)

      store.ecommerce_platform = platform
      store.save
    end
  end

  desc 'Create records required for billing'
  task setup_billing: :environment do
    require_relative '../../db/seeds/billing.rb'
    SeedBilling.new.run
  end

  desc 'Ensure all stores have draft bundles'
  task ensure_draft_bundles: :environment do
    stores_without_bundles = Store.left_outer_joins(:bundles)
                               .where(bundles: { id: nil })
    stores_without_bundles.each do |store|
      Bundles::CreateBundle.run store: store
    end
  end

  desc 'Export stores info to csv'
  task intercom_fix_csv: :environment do
    query = <<SQL
    SELECT users.email,
           stores.id AS store_id, stores.name AS store_name,
           stores.created_at AS first_installed_at, stores.installed_at AS latest_installed_at,
           CASE WHEN stores.access_token IS NULL THEN 'inactive' ELSE 'active' END AS store_status,
           ecommerce_platforms.name AS ecommerce_platform
    FROM users
    LEFT OUTER JOIN stores ON users.id = stores.user_id
    INNER JOIN ecommerce_platforms ON ecommerce_platforms.id = stores.ecommerce_platform_id
SQL

    filepath = File.join(Rails.root, "tmp", "stores.csv")
    export_query = "COPY (#{query}) TO '#{filepath}' WITH CSV DELIMITER ',' HEADER;"
    connection = ActiveRecord::Base.connection_pool.checkout.raw_connection
    connection.exec(export_query)
  end

  desc 'Restrict outgoing emails at user scope'
  task restrict_emails: :environment do
    Store.all.includes(:setting_objects).find_each do |s|
      s.update_settings(:global, outgoing_emails_initially_restricted: true) if s.settings(:global).restrict_outgoing_emails
      s.update_settings(:global, restrict_outgoing_emails: true)
    end
  end

  desc 'Require email templates check'
  task require_templates_check: :environment do
    Store.all.includes(:setting_objects).find_each do |s|
      s.update_settings(:reviews, check_required: true)
      s.update_settings(:questions, check_required: true)
      s.update_settings(:promotions, check_required: true)
    end
  end
end
