module Payments
  class ShopifyRecurringCharge < RecurringCharge
    include Priceable

    RETURN_URL = Rails.application.routes.url_helpers.confirm_back_shopify_payments_url(Rails.configuration.action_controller.default_url_options)

    def initialize(subscription)
      super
      @api = ::Shopify::ApiWrapper.new(subscription.store)
    end

    def create

      params = { name:          subscription.plan_name,
                 price:         subscription.total_price_in_dollars,
                 terms:         subscription.plan_description,
                 capped_amount: subscription.overages_limit,
                 return_url:    RETURN_URL }
      params[:test] = true if payments_test_mode?

      @api.within_session do
        ShopifyAPI::RecurringApplicationCharge.create params
      end
    end

    def activate
      @api.within_session do
        charge = fetch_charge

        if charge.status == "accepted"
          successful = charge.activate
          if successful
            Result.new success: true, entity: charge, status: "active"
          else
            Result.new success: false, entity: charge, status: "error_during_activation"
          end
        else
          Result.new success: false, entity: charge, error: "is #{charge.status}"
        end
      end
    rescue ActiveResource::UnauthorizedAccess => ex
      reset_store_token
      Result.new success: false, error: 'Unauthorized access error from API. Please ensure that your store is properly configured'
    end

    def cancel
      @api.within_session do
        charge = fetch_charge

        if charge.status == "active"
          charge.destroy
          Result.new success: true, entity: subscription
        else
          Result.new success: false, entity: subscription, status: "inactive_charge"
        end
      end
    rescue ActiveResource::UnauthorizedAccess => ex
      reset_store_token
      Result.new success: false, error: 'Unauthorized access error from API. Please ensure that your store is properly configured'
    end

    def charge_extras(amount, description)
      params = { price: in_dollars(amount), description: description }

      @api.within_session do
        charge = ShopifyAPI::UsageCharge.new params
        charge.prefix_options[:recurring_application_charge_id] = subscription.id_from_provider
        if charge.save
          OpenStruct.new amount: amount, description: description, id_from_provider: charge.id, status: :success
        else
          OpenStruct.new amount: amount, description: description, status: :error, error: charge.errors.full_messages
        end
      end
    end

    private

    def reset_store_token
      return nil unless subscription
      store = subscription.store
      store.reset_token if store.present?
    end

    def fetch_charge
      charge_id = subscription.id_from_provider
      ShopifyAPI::RecurringApplicationCharge.find charge_id
    end

    def payments_test_mode?
      !!ENV['SHOPIFY_PAYMENTS_TEST_MODE']
    end
  end
end
