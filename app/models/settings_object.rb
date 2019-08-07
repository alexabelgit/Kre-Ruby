class SettingsObject < RailsSettings::SettingObject
  belongs_to :target, polymorphic: true, touch: true

  after_save           :complete_onboarding_step
  after_commit         :shopify_sync, if: Proc.new { |s| s.target.class.method_defined?(:shopify?) && s.target.shopify? }

  def days_to_repeat_review_request=(value)
    super value.to_i
  end

  def days_to_send_review_request=(value)
    super value.to_i
  end

  def enable_repeat_review_request=(value)
    super value&.to_i&.positive?
  end

  def notify_customers_at=(value)
    super(Time.new(value[1], value[2], value[3], value[4], value[5]))
  end

  validate do
    if var == 'reviews'
      unless days_to_repeat_review_request.is_a?(Integer)
        errors.add(:base, 'Invalid days to repeat review request')
      end

      if !days_to_send_review_request.is_a?(Integer) || !(0..90).cover?(days_to_send_review_request)
        errors.add(:base, 'Days to send review request should be positive and its maximum value is 90')
      end

      unless Order::STATUSES[trigger.to_sym].present?
        errors.add(:base, 'Invalid review request trigger')
      end

      if review_request_mail_subject.nil? || !(1..78).cover?(review_request_mail_subject.length)
        errors.add(:base, 'Email subject cannot be blank or too long')
      end

      if review_request_mail_body.nil? || !(1..7800).cover?(review_request_mail_body.length)
        errors.add(:base, 'Email body cannot be blank or too long')
      end

      if repeat_review_request_mail_subject.nil? || !(1..78).cover?(repeat_review_request_mail_subject.length)
        errors.add(:base, 'Email subject cannot be blank or too long')
      end

      if repeat_review_request_mail_body.nil? || !(1..7800).cover?(repeat_review_request_mail_body.length)
        errors.add(:base, 'Email body cannot be blank or too long')
      end

      if comment_mail_subject.nil? || !(1..78).cover?(comment_mail_subject.length)
        errors.add(:base, 'Email subject cannot be blank or too long')
      end

      if comment_mail_body.nil? || !(1..7800).cover?(comment_mail_body.length)
        errors.add(:base, 'Email body cannot be blank or too long')
      end

      if target.facebook_active?
        if facebook_post_template.present? && !(0..7800).cover?(facebook_post_template.length)
          errors.add(:base, 'Facebook post template should be shorter')
        end
      end

      if target.twitter_active?
        if tweet_template.present? && !(0..140).cover?(tweet_template.length)
          errors.add(:base, 'Tweet template should be shorter')
        end
      end
    end

    if var == 'questions'
      if comment_mail_subject.nil? || !(1..78).cover?(comment_mail_subject.length)
        errors.add(:base, 'Email subject cannot be blank or too long')
      end

      if comment_mail_body.nil? || !(1..7800).cover?(comment_mail_body.length)
        errors.add(:base, 'Email body cannot be blank or too long')
      end

      if target.facebook_active?
        if facebook_post_template.present? && !(0..7800).cover?(facebook_post_template.length)
          errors.add(:base, 'Facebook post template should be shorter')
        end
      end

      if target.twitter_active?
        if tweet_template.present? && !(0..140).cover?(tweet_template.length)
          errors.add(:base, 'Tweet template should be shorter')
        end
      end
    end

    if var == 'agents'
      if default_name.nil? || !(1..30).cover?(default_name.length)
        errors.add(:base, 'Agent name cannot be blank or too long')
      end
    end

    if var == 'profanity'
      errors.add(:base, 'Agent name cannot be blank or too long') if custom_filter.empty?
    end
  end

  private

  def shopify_sync
    case var
    when 'reviews'
      sync_global_metafields if setting_changed?(:easy_reviews)
    when 'questions'
      sync_global_metafields if setting_changed?(:enabled)
    when 'widgets'
      keys = %i(product_summary_position product_rating_position product_rating_layout product_summary_show_qa)
      sync_global_metafields if any_setting_changed?(*keys)
    when 'design'
      keys = %i(theme custom_stylesheet_code custom_stylesheet_active rounded shadows)
      sync_global_metafields if any_setting_changed?(*keys)
    when 'global'
      if setting_changed?(:locale)
        sync_global_metafields
        PushSnippetsWorker.perform_async(target.id)
      end
    end
  end


  def sync_global_metafields
    SyncGlobalMetafieldsWorker.perform_async(target.id)
  end

  def complete_onboarding_step
    onboarding = target.settings(:onboarding)
    if saved_change_to_value?
      case var.to_sym
      when :background_workers
        # TODO: are we changing one setting to trigger a change for another? Why don't we directly update orders_imported for example?
        onboarding.update_attributes(orders_imported: true)  if setting_changed?(:orders_seeded)
        onboarding.update_attributes(reviews_imported: true) if setting_changed?(:reviews_seeded)
        onboarding.update_attributes(q_a_imported: true)     if setting_changed?(:questions_seeded)
      when :social_accounts
        if setting_changed?(:facebook_page_id) || setting_changed?(:twitter_user_id)
          if setting_value(:facebook_page_id) != nil
            SettingsObject.where(var: 'social_accounts').where("value LIKE '%facebook_page_id: ''#{setting_value(:facebook_page_id)}''%'").each do |settings_object|
              unless settings_object == self
                settings_object.target.settings(:social_accounts).update_attributes(facebook_page_id: nil)
                settings_object.target.settings(:social_accounts).update_attributes(facebook_page_name: nil)
                if settings_object.target.settings(:social_accounts).twitter_user_id == nil
                  settings_object.target.settings(:onboarding).update_attributes(social_accounts_connected: false)
                end
              end
            end
          end
          onboarding.update_attributes(social_accounts_connected: true)
        end
      when :reviews
        if setting_changed?(:review_request_mail_subject) || setting_changed?(:review_request_mail_body) ||
           setting_changed?(:repeat_review_request_mail_body) || setting_changed?(:repeat_review_request_mail_subject)
          onboarding.update_attributes(review_request_email_templates_personalized: true)
        end
        if setting_changed?(:facebook_post_template) || setting_changed?(:tweet_template)
          onboarding.update_attributes(review_social_templates_customized: true)
        end
        review_features = %i(auto_publish easy_reviews grid_layout repeated_reviews show_titles show_date show_media_gallery media_reviews auto_publish_media media_collage_in_social_posts)
        onboarding.update_attributes(features_customized: true) if any_setting_changed?(*review_features)
      when :questions
        onboarding.update_attributes(q_a_email_templates_customized: true) if setting_changed?(:comment_mail_body)
        if setting_changed?(:facebook_post_template) || setting_changed?(:tweet_template)
          onboarding.update_attributes(q_a_social_templates_customized: true)
        end
        qa_features = %i(enabled show_date)
        onboarding.update_attributes(features_customized: true) if any_setting_changed?(*qa_features)
      when :widgets
        if setting_changed?(:stylesheet_in_use) && setting_to_b?(:stylesheet_in_use)
          onboarding.update_attributes(stylesheet_embedded: true)
        end
        if (setting_changed?(:product_rating_in_use)  ||
            setting_changed?(:product_summary_in_use) ||
            setting_changed?(:product_tabs_in_use))   &&
            setting_to_b?(:product_rating_in_use)     &&
            setting_to_b?(:product_summary_in_use)    &&
            setting_to_b?(:product_tabs_in_use)
          onboarding.update_attributes(widgets_embedded: true)
        end
        optional_widgets = %i(review_journal_in_use review_slider_in_use sidebar_in_use reviews_facebook_tab_in_use)
        if any_setting_changed?(*optional_widgets) && optional_widgets.any?(&method(:setting_to_b?))
          onboarding.update_attributes(optional_widgets_embedded: true)
        end
      when :design
        design_settings = %i(items_per_page primary_color theme show_hc_branding rounded shadows)
        onboarding.update_attributes(design_customized: true) if any_setting_changed?(*design_settings)
      end
    end
  end

  def any_setting_changed?(*keys)
    keys.any?(&method(:setting_changed?))
  end

  def setting_changed?(key)
    key = key.to_s
    previous_changes.present? && previous_changes['value'].present? && previous_changes['value'].first[key] != previous_changes['value'].last[key]
  end

  def setting_to_b?(key)
    v = setting_value(key)
    v.present? && v.to_b
  end

  def setting_value(key)
    key = key.to_s
    value[key]
  end
end
