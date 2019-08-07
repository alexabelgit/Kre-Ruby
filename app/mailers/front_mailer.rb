class FrontMailer < ApplicationMailer
  default from: "Helpful Bot <#{ENV['FRONT_MAILER_DEFAULT_FROM']}>"
  layout 'mailer/front'

  def review_request(review_request, uid, test=false)
    @review_request = review_request
    @customer       = @review_request.customer
    @store          = @customer.store
    return if send_restricted(@store)
    @helpful_id = uid
    @show_star_labels = show_labels_for_stars(@store)
    @to = test ? "#{@store.user.email}" : @customer.email

    @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email

    # TODO UPDATE WITH PARCING PLACEHOLDERS
    if @review_request.order.present?
      @order_number   = @review_request.order.order_number
      @help_subject = "#{t('help_subject_with_order', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)} #{@order_number}"
    else
      @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"
    end

    additional_args(category:    ['To customer', 'Request', '1st request'],
                    object_id:   @review_request.hashid,
                    object_type: ReviewRequest.name.underscore,
                    helpful_id:  uid)

    I18n.with_locale(@store.settings(:global).locale) do
      mail(to:      @to,
           from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
           subject: @store.settings(:reviews).review_request_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @review_request))
    end
  end

  def repeat_review_request(review_request, uid, test=false)
    @review_request = review_request
    @customer       = @review_request.customer
    @store          = @customer.store
    return if send_restricted(@store)
    @helpful_id = uid
    @show_star_labels = show_labels_for_stars(@store)
    @to = test ? "#{@store.user.email}" : @customer.email

    @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email

    # TODO UPDATE WITH PARCING PLACEHOLDERS
    if @review_request.order.present?
      @order_number   = @review_request.order.order_number
      @help_subject = "#{t('help_subject_with_order', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)} #{@order_number}"
    else
      @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"
    end

    additional_args(category:    ['To customer', 'Request', 'Repeat request'],
                    object_id:   @review_request.hashid,
                    object_type: ReviewRequest.name.underscore,
                    helpful_id:  uid)

    I18n.with_locale(@store.settings(:global).locale) do
      mail(to:      @to,
           from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
           subject: @store.settings(:reviews).repeat_review_request_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @review_request))
    end
  end

  def comment_on_review(comment_id, uid, test=false)
    @comment = Comment.find_by_id(comment_id)
    if @comment.present?
      @store      = @comment.store
      return if send_restricted(@store)
      @customer   = @comment.commentable.customer
      @helpful_id = uid
      @review_request = @comment.commentable.review_request
      @to = test ? "#{@store.user.email}" : @comment.commentable.customer.email

      @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email

      # TODO UPDATE WITH PARCING PLACEHOLDERS
      if @review_request.order.present?
        @order_number   = @review_request.order.order_number
        @help_subject = "#{t('help_subject_with_order', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)} #{@order_number}"
      else
        @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"
      end

      additional_args(category:    ['To customer', 'Review', 'Answer'],
                      object_id:   @comment.commentable.hashid,
                      object_type: Review.name.underscore)

      I18n.with_locale(@store.settings(:global).locale) do
        mail(to:      @to,
             from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
             subject: @store.settings(:reviews).comment_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @comment.commentable))
      end
    end
  end

  def comment_on_question(comment_id, uid, test=false)
    @comment = Comment.find_by_id(comment_id)
    if @comment.present?
      @store      = @comment.store
      return if send_restricted(@store)
      @customer   = @comment.commentable.customer
      @helpful_id = uid
      @to = test ? "#{@store.user.email}" : @comment.commentable.customer.email

      @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email
      @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"

      additional_args(category:    ['To customer', 'Q&A', 'Answer'],
                      object_id:   @comment.commentable.hashid,
                      object_type: Question.name.underscore)

      I18n.with_locale(@store.settings(:global).locale) do
        mail(to:      @to,
             from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
             subject: @store.settings(:questions).comment_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @comment.commentable))
      end
    end
  end

  def positive_review_follow_up(review, uid, test=false)
    @review         = review
    @store          = @review.store
    return if send_restricted(@store)
    @helpful_id     = uid
    @customer       = @review.customer
    @review_request = @review.review_request
    @to = test ? "#{@store.user.email}" : @review.customer.email

    @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email

    # TODO UPDATE WITH PARCING PLACEHOLDERS
    if @review.order.present?
      @order_number = @review.order.order_number
      @help_subject = "#{t('help_subject_with_order', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)} #{@order_number}"
    else
      @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"
    end

    additional_args(category:    ['To customer', 'Review', 'Positive follow-up'],
                    object_id:   @review.hashid,
                    object_type: Review.name.underscore)

    I18n.with_locale(@store.settings(:global).locale) do
      mail(to:      @to,
           from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
           subject: @store.settings(:reviews).positive_review_followup_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @review))
    end
  end

  def critical_review_follow_up(review, uid, test=false)
    @review         = review
    @store          = @review.store
    return if send_restricted(@store)
    @helpful_id     = uid
    @customer       = @review.customer
    @review_request = @review.review_request
    @to = test ? "#{@store.user.email}" : @review.customer.email

    @help_to = @store.settings(:agents).support_email.present? ? @store.settings(:agents).support_email : @store.user.email

    # TODO UPDATE WITH PARCING PLACEHOLDERS
    if @review.order.present?
      @order_number = @review.order.order_number
      @help_subject = "#{t('help_subject_with_order', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)} #{@order_number}"
    else
      @help_subject = "#{t('help_subject', scope: 'layouts.mailer.front', locale: @store.settings(:global).locale)}"
    end

    additional_args(category:    ['To customer', 'Review', 'Critical follow-up'],
                    object_id:   @review.hashid,
                    object_type: Review.name.underscore)

    I18n.with_locale(@store.settings(:global).locale) do
      mail(to:      @to,
           from:    "#{ @store.name } via HelpfulCrowd <#{ ENV['FRONT_MAILER_DEFAULT_FROM'] }>",
           subject: @store.settings(:reviews).critical_review_followup_mail_subject.parse_placeholders(Placeholders::FRONT_MAILER_SUBJECT, @review))
    end
  end

  private

  def show_labels_for_stars(store)
    !store.settings(:admin_only).hide_labels_for_stars.to_b
  end

  def send_restricted(store)
    store.settings(:admin_only).restrict_outgoing_emails.to_b || store.settings(:global).restrict_outgoing_emails.to_b
  end
end
