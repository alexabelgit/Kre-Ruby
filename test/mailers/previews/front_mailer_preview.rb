# Preview all emails at http://localhost:3000/rails/mailers/front_mailer

class FrontMailerPreview < ActionMailer::Preview
  def review_request
    uid = 123_456
    store = Store.take
    customer = Customer.where(name: "Custo Testus") || Customer.take
    product = Product.take
    review_request = ReviewRequest.where(customer: customer).take || ReviewRequests::CreateReviewRequest.run(customer: customer, product_ids: [product.id]).result

    FrontMailer.review_request(review_request, uid)
  end

  def repeat_review_request
    uid = 123_456
    store = Store.take
    customer = Customer.take
    product = Product.take
    review_request = ReviewRequests::CreateReviewRequest.run(customer: customer, product_ids: [product.id]).result

    FrontMailer.repeat_review_request(review_request, uid)
  end

  def positive_review_follow_up
    uid = 123_456
    review = Review.take

    FrontMailer.positive_review_follow_up(review, uid)
  end

  def critical_review_follow_up
    uid = 123_456
    review = Review.take

    FrontMailer.critical_review_follow_up(review, uid)
  end

  def comment_on_review
    uid = 123_456
    comment = Comment.where(commentable_type: "Review").take
    # comment = Comment.create(user_id: User.take.id, body: "Just another comment", display_name: "Jack", commentable: Review.take)
    comment_id = comment.id

    FrontMailer.comment_on_review(comment_id, uid)
  end

  def comment_on_question
    uid = 123_456
    comment = Comment.where(commentable_type: "Question").take
    # comment = Comment.create(user_id: User.take.id, body: "Just another comment", display_name: "Jack", commentable: Question.take)
    comment_id = comment.id

    FrontMailer.comment_on_question(comment_id, uid)
  end
end
