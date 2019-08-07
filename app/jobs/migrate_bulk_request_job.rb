class MigrateBulkRequestJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.imported_review_requests.where(marked_for_deletion: true).destroy_all

    Product.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      store.imported_review_requests.where(marked_for_deletion: false).each do |imported_review_request|

        order = Order.create(customer: imported_review_request.customer, order_date: DateTime.current)
        imported_review_request.products.each do |product|
          order.products << product
        end
        ReviewRequest.create(order: order, scheduled_for: imported_review_request.scheduled_for)
        imported_review_request.destroy
      end
    end
    Product.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(migrating_imported_review_requests: false)
  end
end
