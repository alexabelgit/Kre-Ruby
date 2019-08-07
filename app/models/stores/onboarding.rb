module Stores
  module Onboarding
    extend ActiveSupport::Concern

    def onboarding
      Rails.cache.fetch [settings(:onboarding), "onboarding-summary"] do
        steps             = onboarding_steps
        recommended_steps = steps.select { |step| step[:optional] == false }
        step_statuses     = recommended_steps.map { |value| value[:status] }

        completed   = step_statuses.count(:complete)
        left        = step_statuses.count(:incomplete)
        total_steps = recommended_steps.count

        {
          steps_completed: completed,
          steps_left:      left,
          steps_total:     total_steps,
          progress:        completed.percent_of(total_steps).round
        }
      end
    end

    def onboarding_steps_completed
      onboarding[:steps_completed]
    end

    def onboarding_steps_total
      onboarding[:steps_total]
    end

    def onboarded?
      onboarding[:progress] >= 100
    end

    def onboarding_steps
      route_of = Rails.application.routes.url_helpers

      steps = [
        onboarding_step(:store_connected, false, completable: false),
        onboarding_step(:global_settings_customized, route_of.general_back_settings_path),
        (onboarding_step(:products_created, route_of.back_products_path) if custom?),
        onboarding_step(:review_request_email_templates_personalized, route_of.emails_back_reviews_path),

        (onboarding_step(:widgets_embedded, route_of.widgets_back_settings_path) if custom?),
        (onboarding_step(:shopify_installation_processing, route_of.widget_console_back_tools_path, completable: false, predicate: :processing) if show_shopify_installation_processing?),
        (onboarding_step(:shopify_installation_successful, route_of.widget_console_back_tools_path, completable: false, predicate: :complete) if show_shopify_installation_successful?),
        (onboarding_step(:shopify_installation_failed, route_of.widget_console_back_tools_path, completable: false, predicate: :warning) if show_shopify_installation_failed?),
        (onboarding_step(:shopify_installation_checking, route_of.widget_console_back_tools_path, completable: false, predicate: :processing) if show_shopify_check_installation?),

        onboarding_step(:design_customized, route_of.design_back_settings_path),
        onboarding_step(:features_customized, route_of.features_back_settings_path),

        (onboarding_step(:orders_imported, route_of.seed_back_tools_path(anchor: 'import-orders'), optional: true) unless custom?),
        onboarding_step(:reviews_imported, route_of.seed_back_tools_path(anchor: 'import-reviews'), optional: true),
        onboarding_step(:social_accounts_connected, route_of.social_accounts_back_settings_path, optional: true),
        (onboarding_step(:optional_widgets_embedded, route_of.widgets_back_settings_path, optional: true) unless custom?)
      ]

      steps.compact
    end


    private

    def onboarding_step(name, target, predicate: nil, completable: true, optional: false)
      status  = predicate ||= settings(:onboarding).send(name) ? :complete : :incomplete
      snippet = I18n.exists?("onboarding.#{name.to_s}.snippet", :en) ? I18n.t("onboarding.#{name.to_s}.snippet") : nil
      {
        type:                name,
        title:               I18n.t("onboarding.#{name.to_s}.title"),
        description:         I18n.t("onboarding.#{name.to_s}.description.html"),
        description_complete:
                             I18n.t("onboarding.#{name.to_s}.description_complete.html",   default: I18n.t("onboarding.#{name.to_s}.description.html")),
        snippet:             snippet,
        status:              status,
        target:              target,
        completable:         completable,
        optional:            optional,
      }
    end
  end
end
