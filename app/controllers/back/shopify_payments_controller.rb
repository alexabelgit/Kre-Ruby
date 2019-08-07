module Back
  class ShopifyPaymentsController < BackController
    skip_before_action :check_live

    def new
      subscription = Subscription.find params[:subscription_id]

      result = Payments::RecurringCharge.build(subscription).create

      if result.blank?
        redirect_to_billing_with_error 'Failed to access Shopify API. Please ensure that your store is properly configured'
        return
      end

      if result.errors.present?
        error_message = result.errors.full_messages.join(' ')
        redirect_to_billing_with_error error_message
        return
      end

      attributes = Shopify::PaymentResultParser.new(result).to_attributes
      inputs = attributes.merge(subscription: subscription)
      outcome = commands[:update_subscription].run inputs

      if outcome.valid?
        redirect_to result.confirmation_url
      else
        error_message = outcome.errors.full_messages.join
        redirect_to_billing_with_error error_message
      end
    end

    def confirm
      subscription = Subscription.find_by id_from_provider: params[:charge_id]
      outcome = commands[:confirm_subscription].run subscription: subscription

      if outcome.valid?
        flash[:success] = "Subscription successfully updated", :fade
      else
        errors = outcome.errors.full_messages.join
        if errors == "Charge is declined"
          flash[:error] = t '.declined.html', link: helpers.kb_article_url('uninstall_shopify')
        else
          flash[:error] = "Subscription update failed. Please try again or contact us if this keeps happening."
        end
      end
      redirect_to billing_back_settings_path
    end

    private

    def redirect_to_billing_with_error(error_message)
      flash[:error] = "Failed to initialize payment. #{error_message}"
      redirect_to billing_back_settings_path
    end

    def commands
      {
        update_subscription: Subscriptions::UpdateSubscription,
        confirm_subscription: Subscriptions::ConfirmShopifySubscription
      }
    end

    def payment_info(result)
      result.attributes.slice(:status, :id, :billing_on, :activated_on, :cancelled_on )
    end
  end
end
