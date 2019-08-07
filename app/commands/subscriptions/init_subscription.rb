module Subscriptions
  class InitSubscription < ApplicationCommand
    object :bundle

    def execute
      if bundle.platform.shopify?
        subscription = create_subscription bundle, :shopify
        DataStruct.new subscription: subscription, platform: :shopify
      else
        user = bundle.store.user
        subscription = fetch_latest_subscription bundle, :chargebee

        hosted_page = Payments::ChargebeeHostedPage.build(user, bundle, subscription)

        update_subscription subscription, hosted_page.id
        DataStruct.new platform: :chargebee, hosted_page: hosted_page, subscription: subscription, action: :create
      end
    end

    private

    def update_subscription(subscription, hosted_page_id)
      new_state = subscription.cancelled? ? :reactivating : :pending
      compose Subscriptions::UpdateSubscription, subscription: subscription, hosted_page_id: hosted_page_id, state: new_state
    end

    def fetch_latest_subscription(bundle, processing_platform)
      store = bundle.store
      subscription = store.subscriptions.cancelled.
                       where(processing_platform: processing_platform)
                       .recently_cancelled.last
      if subscription.present?
        subscription.update bundle: bundle
        subscription
      else
        create_subscription bundle, processing_platform
      end
    end

    def create_subscription(bundle, processing_platform)
      Subscription.create bundle: bundle, processing_platform: processing_platform
    end
  end
end
