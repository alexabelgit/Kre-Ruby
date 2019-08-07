module Stores
  module Settings
    extend ActiveSupport::Concern

    included do
      has_settings class_name: SettingsObject.to_s do |s|
        s.key :agents

        s.key :admin_only, defaults: {
          restrict_outgoing_emails: false,
          hide_labels_for_stars: false,
          notes: ''
        }

        s.key :background_workers, defaults: {
          product_seed_running:                    false,

          order_seed_running:                      false,
          orders_seeded:                           false,

          review_requests_seed_running:            false,
          review_requests_seeded:                  false,

          reviews_seed_running:                    false,
          reviews_seeded:                          false,

          questions_seed_running:                  false,
          questions_seeded:                        false,

          migrating_imported_reviews:              false,
          migrating_imported_questions:            false,
          migrating_imported_review_requests:      false,

          products_uploaded:                       false,
          uploading_products:                      false,

          proceed_on_hold_review_requests_running: false,

          intercom_sync_scheduled:                 false
        }

        s.key :customers, defaults: {
          display_name_policy: :initialize_first # This initializes the first PART of
                                                 # name, we do not know if it's really
                                                 # the first name or not.
                                                 #
                                                 # Other options:
                                                 # :initialize_all  - initializes all
                                                 #                    parts of name
                                                 # :initialize_none - does not initialize
                                                 #                    any part of the name
        }

        # TODO CLEANUP
        s.key :onboarding, defaults: {
          store_connected:                             true,
          global_settings_customized:                  false,
          products_created:                            false,
          widgets_embedded:                            false,
          design_customized:                           false,
          features_customized:                         false,
          review_request_email_templates_personalized: false,
          stylesheet_embedded:                         false,
          orders_imported:                             false,
          reviews_imported:                            false,
          social_accounts_connected:                   false,
          optional_widgets_embedded:                   false
        }

        s.key :global, defaults: {
          keep_hc_active:                 false, # This will continue accepting reviews even if the app is uninstalled
          locale:                         :en,
          notify_customers_at:            '12:00'.to_time,
          recaptcha:                      true,
          dismiss_product_update_webhook: false,
          time_zone:                      'UTC',
          date_format:                    'mm/dd/yyyy',
          restrict_outgoing_emails:       true
        }

        s.key :abuse_filters, defaults: {
          enabled:     true,
          use_default: true,
          profanity:   '',
          competitors: ''
        }

        s.key :questions, defaults: {
          enabled:                true, # TODO: refactor to_b-s everywhere

          comment_mail_subject:   I18n.t('default_templates.email.question_answer_mail_subject'),
          comment_mail_body:      I18n.t('default_templates.email.question_answer_mail_body'),
          grid_layout:            'single_column',   #or 'masonry'
          show_date:              true,
          facebook_post_template: nil,
          tweet_template:         nil,
          check_required:         false
        }

        s.key :reviews, defaults: {
          auto_publish:                          true,
          minimum_ratings_to_publish:            1,
          auto_publish_media:                    true,
          easy_reviews:                          true,
          authenticated_reviews:                 false,
          grid_layout:                           'single_column',   #or 'masonry'
          media_layout:                          'grid',   #or 'hero', 'featured'
          show_media_gallery:                    true,
          media_collage_in_social_posts:         true,
          media_reviews:                         true,
          repeated_reviews:                      true,
          show_titles:                           false,
          show_date:                             true,
          check_required:                        false,

          enable_automated_review_request:       true,
          days_to_send_review_request:           7,
          trigger:                               :paid,
          review_request_mail_subject:           I18n.t('default_templates.email.review_request_mail_subject'),
          review_request_mail_body:              I18n.t('default_templates.email.review_request_mail_body'),

          days_to_repeat_review_request:         5,
          enable_repeat_review_request:          true,
          repeat_review_request_mail_body:       I18n.t('default_templates.email.repeat_review_request_mail_body'),
          repeat_review_request_mail_subject:    I18n.t('default_templates.email.repeat_review_request_mail_subject'),

          comment_mail_subject:                  I18n.t('default_templates.email.review_answer_mail_subject'),
          comment_mail_body:                     I18n.t('default_templates.email.review_answer_mail_body'),

          send_positive_review_followup_mail:    false,
          positive_review_followup_mail_subject: I18n.t('default_templates.email.positive_review_followup_mail_subject'),
          positive_review_followup_mail_body:    I18n.t('default_templates.email.positive_review_followup_mail_body'),

          send_critical_review_followup_mail:    false,
          critical_review_followup_mail_subject: I18n.t('default_templates.email.critical_review_followup_mail_subject'),
          critical_review_followup_mail_body:    I18n.t('default_templates.email.critical_review_followup_mail_body'),

          facebook_post_template:                nil,
          tweet_template:                        nil
        }

        s.key :promotions, defaults: {
          mark_reviews_with_incentive: false,
          with_incentive_text:         I18n.t('front.with_incentive.reviews.text'),
          check_required:              false,
        }

        s.key :shopify, defaults: {
          storefront_is_set_up:        false,
          theme_id:                    nil,
          theme_name:                  nil,
          auto_inject_failed:          false,
          auto_inject_steps_remaining: 0,
          auto_inject_try_performed:   false,
          installation_last_checked:   Time.now.utc - 1.hour,
          auto_remove_status:          '',
          api_call_limit_used:         0
        }

        s.key :billing, defaults: {
          trial_ending_email_sent:   false,
          trial_finished_email_sent: false,
          grace_period_email_sent:   false,
          miss_you_email_sent:       false,
          store_deleted_email_sent:  false,
          plan_exceeding_email_sent: false,
          plan_exceeded_email_sent:  false
        }

        s.key :social_accounts, defaults: {
          facebook_page_id:   nil,
          facebook_page_name: nil,
          # TODO we need facebook page handle.. name is not the same.. reverse of the issue with Twitter below

          twitter_user_id:     nil,
          twitter_username:    nil,
          twitter_screen_name: nil,
          # TODO we need to save twitter screen_name as well
        }

        s.key :design, defaults: {
          hide_card_actions: false,
          items_per_page:    12,
          primary_color:     Rails.configuration.colors[:primary],
          theme:             'light',
          show_hc_branding:  true,
          rounded:           true,
          shadows:           false,
          show_store_logo_on_comment:     false,
          show_user_avatar:  true,
          custom_stylesheet_code:   nil,
          custom_stylesheet_active: false,
          pagination_style:  'modern'
        }

        s.key :widgets, defaults: {
          product_rating:                        true,
          product_rating_position:               'auto',
          product_rating_show_review_count:      'false',
          product_rating_show_not_rated:         false,
          product_rating_in_use:                 false,
          product_rating_autoembed:              false,
          product_rating_layout:                 'detailed', # or 'summary'

          product_summary:                       true,
          product_summary_position:              'auto',
          product_summary_show_qa:               true,
          product_summary_in_use:                false,
          product_summary_autoembed:             false,
          product_summary_links:                 true,
          product_summary_show_rating_chart:     true,
          product_summary_show_detailed_text:    false,

          product_tabs_layout:                   'boxed',
          product_tabs_style:                    'classic',
          product_tabs_in_use:                   false,
          product_tabs_open_forms_in_new_tab:    false,
          product_tabs_show_reviews_header:      false,
          product_tabs_show_questions_header:    false,
          product_tabs_reviews_header:           '',    # This empty string is not to be deleted since we have a check on the other side, falling to a internationalized default if it's is empty
          product_tabs_questions_header:         '',    # This empty string is not to be deleted since we have a check on the other side, falling to a internationalized default if it's is empty
          product_tabs_hide_overviews:           false,
          product_tabs_hide_filters:             true,
          product_tabs_autoembed:                false,

          review_journal_open_links_in_new_tab:  false,
          review_journal_in_use:                 false,
          review_journal_disable_product_links:  false,

          review_slider_c2a_enabled:             true,
          review_slider_c2a_text_use_default:    true,
          review_slider_c2a_text_custom:         '',
          review_slider_c2a_url_use_default:     true,
          review_slider_c2a_url_custom:          '',
          review_slider_open_product_in_new_tab: false, # TODO This probably needs to change to review_slider_open_links_in_new_tab
                                                        #      as there may be other links in the slider widget. We will need to migrate
                                                        #      existing data when this change happens. Also there's a method in store.rb
                                                        #      that will need to change to review_slider_open_links_in_new_tab
          review_slider_in_use:                  false,

          reviews_facebook_tab:                  false,
          reviews_facebook_tab_in_use:           false,

          sidebar:                               false, # TODO rename this to sidebar_autoembed and migrate existing stores on production
          sidebar_title:                         '',    # This empty string is not to be deleted since we have a check on the other side, falling to a internationalized default if sidebar_title is empty
          sidebar_position:                      'left',
          sidebar_z_index:                       0,
          sidebar_in_use:                        false,
          sidebar_open_links_in_new_tab:         false,
          sidebar_toggle_transparent_on_mobile:  false,

          stylesheet_in_use:                     false
        }
      end
    end

    def setting_truthy?(category, key)
      settings(category).send(key).to_b
    end

    def setting_falsy?(category, key)
      !settings_truthy?(category, key)
    end

    def settings_truthy?(category, *keys)
      keys.all? { |key| settings(category).send(key).to_b }
    end

    def settings_falsy?(category, *keys)
      keys.none? { |key| settings(category).send(key).to_b }
    end
  end
end
