module Stores
  class CreateStore < ApplicationCommand

    object :user

    string :id_from_provider
    string :url
    string :name
    string :legal_name # TODO default = name
    string :provider

    string :domain, default: nil
    string :access_token, default: nil
    string :phone, default: nil
    string :remote_logo_url, default: nil
    date_time :installed_at, default: nil
    date_time :uninstalled_at, default: nil
    string :timezone, default: nil
    string :plan_name, default: nil
    string :pricing_model, default: 'orders'

    def execute
      ecommerce_platform = fetch_by_provider provider

      params = inputs.merge(ecommerce_platform: ecommerce_platform)
                     .except(:timezone, :provider, :plan_name)
      params[:pricing_model] = 'products' if Flipper.enabled?(:products_billing_for_new_stores)
      store = Store.new params.except(:remote_logo_url)


      ActiveRecord::Base.transaction do
        store.save!
        store.update remote_logo_url: params[:remote_logo_url]
        set_time_zone(store, timezone) if valid_timezone?
        override_default_settings(store)
        create_bundle store
        setup_affiliate_plan(store) if affiliate?
      end
      import_products store
      intercom_create_sync store

      store
    end

    private

    def affiliate?
      plan_name && plan_name == 'affiliate' && provider == 'shopify'
    end

    def fetch_by_provider(provider)
      EcommercePlatform.find_by name: provider
    end

    def valid_timezone?
      timezone? && ActiveSupport::TimeZone[timezone].present?
    end

    def intercom_create_sync(store)
      CreateIntercomCompanyWorker.perform_async(store.id)
    end

    def import_products(store)
      ImportProductsWorker.perform_async(store.id)
    end

    def set_time_zone(store, timezone)
      store.update_settings(:global, time_zone: timezone)
    end

    # Override global defaults with platform specific settings
    def override_default_settings(store)
      return unless store.ecwid?
      store.update_settings :widgets,
                            product_rating_autoembed:  true,
                            product_summary_autoembed: true,
                            product_tabs_autoembed:    true
    end

    def create_bundle(store)
      compose Bundles::CreateBundle, store: store
    end

    def setup_affiliate_plan(store)
      compose Stores::MigrateToAffiliatePlan, store: store
    end
  end
end
