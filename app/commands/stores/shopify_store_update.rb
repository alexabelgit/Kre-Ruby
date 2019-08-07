module Stores
  class ShopifyStoreUpdate < ApplicationCommand
    object :store

    hash :data, default: {}

    def execute
      new_status = data['plan_name']
      if store.active_subscription
        subscription = store.active_subscription
        if new_status == 'frozen'
          change_subscription_state subscription, :suspended
        else
          if subscription.affiliate? && new_status != 'affiliate'
            remove_affiliate_plan store
          end
        end
      elsif store.disabled_subscription
        subscription = store.disabled_subscription
        if new_status != 'frozen' && subscription.suspended?
          change_subscription_state subscription, :active
        end
      end

      resync_shop
    end

    private

    def change_subscription_state(subscription, state)
      compose Subscriptions::ChangeSubscriptionState, subscription: subscription, state: state
    end

    def remove_affiliate_plan(store)
      store.active_bundle.destroy
      compose StartBilling, store: store, reset_trial: true
    end

    def resync_shop
      sync_service = Sync::ShopifyService.new(store: store)
      sync_service.shop(shop_info: data)
    end
  end
end