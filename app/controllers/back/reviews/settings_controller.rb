class Back::Reviews::SettingsController < Back::SettingsController

  def email_templates
  end

  def update_email_templates
    @store.settings(:reviews).update_attributes(setting_params)
    hide_check_announcement
  end

  def social_templates
  end

  def update_social_templates
    respond_to do |format|
      if @store.settings(:reviews).update_attributes(setting_params)
        flash[:success] = 'Social templates updated', :fade

        format.html { redirect_to social_templates_back_reviews_path }
      else
        format.html { render :social_templates }
      end
    end
  end

  def hide_check_announcement
    @store.update_settings(:reviews, check_required: false)
  end

  def send_test_email
    if @store.products.any?
      email_type = params[:email_type]
      uid = SecureRandom.base58
      test_data = get_test_data(email_type)

      FrontMailer.send(email_type, test_data, uid, true).deliver!
    end
  end

  def get_test_data(email_type)
    customer = Customer.where(name: "Test Customer", store: @store).take || Customer.create!(name: "Test Customer", email: "test@example.com", store: @store, id_from_provider: SecureRandom.base58)

    products = Product.where(store: @store).active.last(2)
    products.compact!

    return unless products.present?

    order = customer.orders.create!(id_from_provider: SecureRandom.base58,
            order_number: SecureRandom.base58,
            order_date: DateTime.now)

    tis = products.map do |reviewable|
      TransactionItem.create! order: order, reviewable: reviewable, customer: order.customer
    end
    ti = tis.first

    case email_type
    when "review_request", "repeat_review_request"
      review_request = ReviewRequest.new status: 1, order: order, customer: customer
      order.transaction_items.each do |transaction_item|
        review_request.transaction_items << transaction_item
      end
      review_request.save!
      review_request

    when "positive_review_follow_up", "critical_review_follow_up"
      review = ::Reviews::CreateReview.run!(
                  customer: customer,
                  transaction_item: ti,
                  rating:           5,
                  feedback:         'Test Product: superb quality and fast delivery. Thanks!',
                  review_date:      DateTime.current)
      review.update_attribute(:status, "archived")
      review

    when "comment_on_review"
      # TODO REFACTOR
      review_request = ReviewRequest.new status: 1, order: order, customer: customer
      order.transaction_items.each do |transaction_item|
        review_request.transaction_items << transaction_item
      end
      review_request.save!
      review = ::Reviews::CreateReview.run!(
                  customer: customer,
                  review_request: review_request,
                  transaction_item: ti,
                  rating:           5,
                  feedback:         'Test Product: superb quality and fast delivery. Thanks!',
                  review_date:      DateTime.current)
      review.update_attribute(:status, "archived")
      review_comment = review.comment ||
                Comment.create!(
                  user_id: customer.id,
                  body: "Thank you for a test review!",
                  commentable: review,
                  display_name: @store.name)
      review_comment.id

    when "comment_on_question"
      question = Question.where(product: products.first).answered.last ||
                Question.create!(
                  product: products.first,
                  customer: customer,
                  body: "Is this a test product?")

      question_comment = question.comment ||
                Comment.create!(
                  user_id: customer.id,
                  body: "Thank you for a question about a test product!",
                  commentable: question,
                  display_name: @store.name)
      question_comment.id
    end
  end

end
