require 'chargebee'

module Back
  class SubscriptionsController < BackController
    skip_before_action :check_live

    # POST
    # creates subscription and initiates payment flow depending on platform
    def create
      bundle = Bundle.find params[:bundle_id]

      if params[:bundle]
        bundle_params = params[:bundle]
        Bundles::UpdateBundle.run bundle: bundle, plan_id: bundle_params[:plan], addon_price_ids: bundle_params[:addons]
      end

      outcome = create_or_upgrade_subscription(bundle)
      if outcome.valid?
        result = outcome.result
        if result.platform == :shopify
          redirect_url = new_back_shopify_payment_path(subscription_id: result.subscription.id)
          render json: { platform: result.platform, redirect_url: redirect_url }
        else
          type, message = chargebee_subscription_flash result
          flash[type] = message, :fade
          render json: result, status: 200
        end
      else
        error_message = outcome.errors.full_messages
        render json: { error: error_message }, status: 500
      end
    end

    # POST
    # cancels payment flow and cleans up
    def abort
      subscription = Subscription.find params[:subscription_id]
      outcome = Subscriptions::AbortSubscription.run subscription: subscription
      if outcome.valid?
        render json: { status: :success }
      else
        message = outcome.errors.full_messages
        render json: { error: message }, status: 500
      end
    end

    # DELETE
    # cancels subscription
    def destroy
      subscription = Subscription.find params[:id]
      outcome = Subscriptions::CancelSubscription.run subscription: subscription

      if outcome.valid?
        render json: { status: :success }
      else
        render json: { status: :failed_to_unsubscribe }, status: 500
      end
    end

    private

    def chargebee_subscription_flash(result)
      case result.action
      when :renew
        [:success, 'Your subscription has been renewed']
      when :renew_and_change
        [:success, 'Your subscription has been renewed and switched to a new plan']
      when :update
        [:success, 'Your subscription has been updated. Starting next month, you will be billed based on your new plan']
      else
        [:error, 'Something went wrong during subscription processing. Please try again']
      end
    end

    def create_or_upgrade_subscription(bundle)
      if current_store.shopify?
        Subscriptions::InitSubscription.run bundle: bundle
      else
        change_chargebee_subscription bundle
      end
    end

    def change_chargebee_subscription(bundle)
      subscription = current_store.active_subscription
      if current_store.terminating?
        Subscriptions::ReactivateSubscription.run bundle: bundle, subscription: subscription
      elsif current_store.paid?
        Subscriptions::ChangeSubscription.run bundle: bundle, current_subscription: subscription
      else
        Subscriptions::InitSubscription.run bundle: bundle
      end
    end
  end
end
