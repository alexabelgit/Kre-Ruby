module Payments
  class HostedPageParams
    attr_reader :user, :bundle, :subscription, :reactivate

    MAX_PHONE_LENGTH = 45 # Chargebee has 50 chars per phone number restriction

    def initialize(user, bundle, subscription, reactivate: false)
      @user = user
      @bundle = bundle
      @subscription = subscription
      @reactivate = reactivate
    end

    def checkout_params
      params = build_checkout_params
      apply_discount params, bundle
      apply_reactivation_params(params) if reactivate
      params
    end

    private

    def customer_info
      store = bundle.store
      params = {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        cf_store_id: store.id
      }

      params[:company] =  store.legal_name if store.legal_name.present?
      params[:phone] = store.phone.excerpt(length: MAX_PHONE_LENGTH) if store.phone.present?
      params
    end

    def build_checkout_params
      {
        subscription: subscription_params,
        addons: [],
        customer: customer_info,
        embed: false, # with embed=false we also open hosted page in iframe but paypal tab is available, with embed=true paypal tabs is hidden. Probably bug in chargebee
        iframe_messaging: true
      }
    end

    def subscription_params
      plan_id = bundle.plan_record.chargebee_id
      params = { plan_id: plan_id }
      params[:id] = subscription.id_from_provider if reactivate
      params
    end

    def apply_discount(hosted_page_params, bundle)
      discount = PackageDiscount.bundle_discount bundle
      coupon = discount&.chargebee_id
      hosted_page_params[:subscription][:coupon] = coupon if coupon
    end

    def apply_reactivation_params(hosted_page_params)
      hosted_page_params[:reactivate] = true
      hosted_page_params[:replace_addon_list] = true
    end
  end
end
