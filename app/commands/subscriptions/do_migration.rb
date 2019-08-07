module Subscriptions
  class DoMigration < ApplicationCommand
    def execute
      subscriptions = subscriptions_to_migrate

      shopify_new_helpful = Plan.where(ecommerce_platform: EcommercePlatform.shopify).where(pricing_model: 'products').find_by(slug: 'helpful')

      failed_subscriptions = []

      subscriptions.each do |subscription|
        platform_name = subscription.platform.name

        plan = subscription.bundle.plan_record
        old_slug = plan.slug

        if old_slug == 'helpful'
          next unless platform_name == 'shopify'

          change_plan subscription, shopify_new_helpful
        end

        if ['scoopful', 'handful', 'boxful', 'bucketful', 'plentiful', 'boastful'].include?(old_slug)
          new_slug = "#{old_slug}_#{platform_name}_products_migration"
          new_plan = Plan.where(ecommerce_platform: subscription.platform).find_by(slug: new_slug)

          unless new_plan
            failed_subscriptions << subscription.id
            next
          end

          change_plan subscription, new_plan
        end
      end
      p failed_subscriptions
    end

    def subscriptions_to_migrate
      Subscription.active.joins('INNER JOIN bundle_items ON bundle_items.bundle_id = subscriptions.bundle_id')
        .joins("INNER JOIN plans ON plans.id = bundle_items.price_entry_id AND bundle_items.price_entry_type = 'Plan'")
        .where("plans.pricing_model != 'products'").where("plans.orders_limit > 100000")
        .where('plans.ecommerce_platform_id = 1 OR plans.ecommerce_platform_id = 2')
        .where('subscriptions.migrated_to_products_billing_at IS NULL')
        .includes(bundle: [:bundle_items, :store])
    end

    def change_plan(subscription, new_plan)
      bundle = subscription.bundle
      plan_bundle_item = bundle.bundle_items.where('price_entry_type = ?', 'Plan').first

      plan_bundle_item.update price_entry_id: new_plan.id
      subscription.update migrated_to_products_billing_at: DateTime.current
      bundle.store.update pricing_model: 'products', plan_emails_suspended: true
    end
  end
end
