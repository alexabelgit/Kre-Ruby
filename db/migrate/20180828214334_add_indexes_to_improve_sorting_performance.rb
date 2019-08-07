class AddIndexesToImproveSortingPerformance < ActiveRecord::Migration[5.2]
  def change
    add_index :reviews, :review_date
    add_index :reviews, :created_at
    add_index :reviews, :rating
    add_index :reviews, :votes_count

    add_index :imported_reviews, :created_at

    add_index :questions, :submitted_at
    add_index :questions, :created_at
    add_index :questions, :status

    add_index :review_requests, :created_at
    add_index :review_requests, :status

    add_index :products, :name
    add_index :products, :suppressed

    add_index :stores, :trial_ends_at

    add_index :subscriptions, :state
    add_index :subscriptions, :cancelled_on
    add_index :subscriptions, :expired_at

    add_index :bundles, :state

    add_index :abuse_reports, :created_at
  end
end
