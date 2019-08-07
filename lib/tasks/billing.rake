namespace :billing do
  desc 'Clean ups all subscriptions and bundles'
  task reset_chargebee_billing: :environment do
    STDOUT.puts "This command will wipe out all bundles/subscriptions related to chargebee billing. Are you sure (y/n)?"

    answer = STDIN.gets.strip.downcase

    if answer != 'y'
      STDOUT.puts "Exited without any action"
      return
    end

    # we use chargebee only for ecwid for now
    ecwid_stores = Store.ecwid
    Bundle.where(store: ecwid_stores).not_draft.destroy_all

    STDOUT.puts "Cleaned up all subscriptions for Ecwid stores"
  end

  task delete_base_price_entries: :environment do
    BundleItem.where(price_entry_type: 'BaseEntry').destroy_all
    boxful = Plan.find_by slug: 'boxful'
    Bundle.includes(:plans).select { |b| b.plan_record.nil? }.each do |b|
      BundleItem.create bundle: b, price_entry: boxful
    end
  end

  task change_trial_from_2020_to_july_15: :environment do
    stores = Store.where('trial_ends_at > ?', 1.year.from_now)
    stores.update_all trial_ends_at: Date.parse('July 15 2018')
  end

  task migrate_ecwid_to_helpful: :environment do
    billing_launch_date = Rails.configuration.billing.launch_date
    created_before = billing_launch_date - 1.month
    ecwid_stores = Store.ecwid.where('created_at < ?', created_before)
    helpful_plan = Plan.find_by slug: 'helpful'
    ecwid_stores.each do |store|
      bundle = Bundle.create store: store, state: :active
      BundleItem.create bundle: bundle, price_entry: helpful_plan

      Subscription.create bundle: bundle, state: :active, expired_at: 10.years.from_now, id_from_provider: nil, processing_platform: 'chargebee'
      end
  end

  task set_helpful_plan_billing_date: :environment do
    overages_launch = Rails.configuration.billing.overage_charges_launch_date
    next_billing_at = (overages_launch + 1.month).to_datetime

    helpful_plan = Plan.find_by slug: 'helpful'
    subscriptions_on_helpful = Subscription.joins(bundle: :bundle_items).where("bundle_items.price_entry_id = ? AND bundle_items.price_entry_type = 'Plan'", helpful_plan.id)
    subscriptions_on_helpful.update_all next_billing_at: next_billing_at
  end

  task nullify_deactivated_at_flag_for_active_stores: :environment do
    Store.active.update_all deactivated_at: nil
  end

  task reset_miss_you_and_store_deleted_email_flags: :environment do
    Store.all.includes(:setting_objects).each do |store|
      next unless (store.miss_you_email_sent? && store.store_deleted_email_sent?)
      store.update_settings :billing, miss_you_email_sent: false, store_deleted_email_sent: false
    end
  end

  task cleanup_junk_subscriptions: :environment do
    Bundle.processing.where('created_at < ?', 1.week.ago).destroy_all

    Subscription.where(state: [:initialized, :pending]).where('created_at < ?', 1.week.ago).destroy_all

    Subscription.where('bundle_id IS NOT NULL')
      .includes(:bundle).select { |s| s.bundle.nil? }.each(&:destroy)
  end

  task reset_helpful_subscriptions_billing_date: :environment do
    helpful_plan = Plan.find_by slug: 'helpful'
    subscriptions_on_helpful = Subscription.joins(bundle: :bundle_items)
                                            .where("bundle_items.price_entry_id = ? AND bundle_items.price_entry_type = 'Plan'", helpful_plan.id)

    with_passed_next_billing_date = subscriptions_on_helpful.where('next_billing_at < ?', DateTime.current)

    with_passed_next_billing_date.find_each do |subscription|
      next_billing_at = (subscription.next_billing_at + 1.month).to_datetime
      Subscriptions::RenewSubscription.run subscription: subscription,
                                           next_billing_at: next_billing_at,
                                           updated_at: DateTime.current
    end
  end

  task clean_base_price_bundle_items: :environment do
    BundleItem.where(price_entry_type: 'BasePrice').destroy_all
  end


  task set_gifted_flag_for_current_gifted_subscriptions: :environment do
    Subscription.where('id_from_provider IS NULL').update_all gifted: true
  end

  task migrate_shopify_expired_trials_to_helpful: :environment do
    Store.shopify.where('trial_ends_at < ?', DateTime.current).find_each do |store|
      Stores::MigrateToHelpfulPlan.run store: store
    end
  end

  task set_all_plans_as_orders_based: :environment do
    Plan.where(pricing_model: nil).update_all pricing_model: 'orders'
  end


  task migrate_stores_without_subscription_to_products_billing: :environment do
    stores = Store.active.includes(:bundles).where(pricing_model: 'orders').select { |s| !s.subscription? }
    stores.each { |s| s.update pricing_model: 'products' }
  end
end
