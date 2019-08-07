class SyncService
  def initialize(store: , provider: nil)
    @store               = store
    @provider            = provider || store.provider
    @sync_service_object = "Sync::#{@provider.capitalize}Service".constantize.new(store: @store, provider: @provider)
  end

  def products(**args)
    args = args.slice(:skip_reindex_children, :skip_image_update)

    api_products = @sync_service_object.send(:products)

    sync_id = "sync-#{@store.hashid}-#{DateTime.current}"
    batch_size = Rails.configuration.products_sync_batch_size
    api_products.each_slice(batch_size) do |api_products_batch|
      next if api_products_batch.blank?

      ProductsSyncBatches::SyncBatch.run store: @store, sync_id: sync_id,
                                         products_info: api_products_batch.as_json,
                                         arguments: args
    end
  end

  def product(**args)
    id_from_provider = args[:id_from_provider].to_s
    skip_reindex_children = args.delete(:skip_reindex_children) || false
    product = @store.products.find_by id_from_provider: id_from_provider

    api_product = args[:api_product]
    api_product ||= @sync_service_object.product api_product: api_product, id_from_provider: id_from_provider

    if api_product.nil?
      if product.present?
        ::Products::UpdateProduct.run product: product, status: 'archived', suppressed: true
      end
      return false
    end

    if product.present?
      skip_update = api_product.updated_at <= product.last_synced_at
      return false if skip_update

      name = api_product.name.presence || product.name
      params = {
          product: product,
          name: name, storefront_availability: api_product.storefront_availability,
          url:  api_product.url,
          skus: api_product.skus,
          last_synced_at: api_product.updated_at,
          initiated_by_user: false
      }
      ::Products::UpdateProduct.run params
    else
      name = api_product.name.presence || api_product.id_from_provider
      params = {
          id_from_provider:        api_product.id_from_provider,
          name:                    name,
          store:                   @store,
          storefront_availability: api_product.storefront_availability,
          url:                     api_product.url,
          skus:                    api_product.skus,
          last_synced_at:          api_product.updated_at,
          initiated_by_user:       false,
          skip_reindex_children:   skip_reindex_children
      }
      outcome = ::Products::CreateProduct.run params
      product = outcome.result
    end

    skip_image_update = args[:skip_image_update]
    ::Products::SetFeaturedImage.run(product: product, image_url: api_product.image_url, image_updated_at: api_product.image_updated_at) unless skip_image_update

    OpenStruct.new object:            product,
                   wrapper:           api_product,
                   id_from_provider:  id_from_provider
  end

  def order_id_from_providers(**args)
    @sync_service_object.send(:order_id_from_providers, args)
  end

  def orders(**args)
    result          = []
    import          = args[:import] || false
    order_wrappers  = @sync_service_object.send(:orders, args)
    order_wrappers.reverse_each do |order_wrapper|
      if order_wrapper
        order = self.order(id_from_provider: order_wrapper.id_from_provider, order_wrapper: order_wrapper, import: import)
        result << order if order
      end
    end
    StoreSubscriptionUsage.refresh
    result
  end

  def order(**args)
    id_from_provider   = args[:id_from_provider].to_s
    order_wrapper      = args[:order_wrapper]
    import             = args[:import] || false
    order_wrapper    ||= @sync_service_object.send(:order, args)

    return false unless order_wrapper.success

    order = @store.orders.find_by id_from_provider: id_from_provider
    result = nil

    trigger_validated = order_wrapper.trigger_validated
    result = OpenStruct.new ({
       wrapper:           order_wrapper,
       object:            order,
       id_from_provider:  id_from_provider,
       trigger_validated: trigger_validated
    }) unless trigger_validated

    service_result_customer = self.customer(order_wrapper: order_wrapper, skip_reindex_children: import)
    customer = service_result_customer&.object
    if order.blank? && customer&.persisted? && order_wrapper.trigger_validated && (import || DateTime.current <= (order_wrapper.order_date + 2.months))
      order = Order.create(id_from_provider: order_wrapper.id_from_provider,
                           order_number:     order_wrapper.order_number,
                           order_date:       order_wrapper.order_date,
                           customer:         customer)
    end

    if order.present? && order.persisted?
      sync_order_transaction_items(order_wrapper, order)
      order = @store.orders.find_by_id(order.id)
    end

    result ||= OpenStruct.new ({
        object:            order.present? && order.persisted? ? order : nil,
        wrapper:           order_wrapper,
        id_from_provider:  id_from_provider,
        trigger_validated: trigger_validated
    })

    result
  end

  def customer(**args)
    customer_wrapper        = args[:customer_wrapper]
    customer_wrapper      ||= @sync_service_object.send(:customer, args)
    return nil if customer_wrapper.nil?

    skip_reindex_children   = args[:skip_reindex_children] || false

    customer = @store.customers.find_by_id_from_provider(customer_wrapper.id_from_provider)

    if customer.present?
      customer.update_attributes(email:                 customer_wrapper.email,
                                 name:                  customer_wrapper.name,
                                 skip_reindex_children: skip_reindex_children)
    else
      customer = Customer.create(email:                 customer_wrapper.email,
                                 name:                  customer_wrapper.name || customer_wrapper.email,
                                 id_from_provider:      customer_wrapper.id_from_provider,
                                 store:                 @store,
                                 skip_reindex_children: skip_reindex_children)
    end

    OpenStruct.new ({
        object:           customer,
        wrapper:          customer_wrapper,
        id_from_provider: customer_wrapper.id_from_provider
    })
  end

  def review_request(**args)
    order_id_from_provider   = args[:order_id_from_provider]
    service_result_order     = args[:service_result_order]
    service_result_order   ||= self.order(id_from_provider: order_id_from_provider)

    return false unless service_result_order

    order = service_result_order.object

    return false unless order.present?

    # Cancel review request when order is cancelled
    if service_result_order.wrapper.present? && service_result_order.wrapper.status == 'cancelled'
      order.review_request.cancel! if order.review_request.present?
    end

    # Create and update review request
    if order.transaction_items.any?
      if order.review_request.blank?
        outcome = ::ReviewRequests::CreateReviewRequest.run customer:          order.customer,
                                                            transaction_items: order.transaction_items,
                                                            scheduled_for:     @store.active? ? @store.get_scheduled_for : nil,
                                                            status:            @store.active? ? :scheduled : :on_hold,
                                                            order:             order
      else
        order.review_request.hold! if @store.inactive?
      end
    end
    order = @store.orders.find_by_id(order.id)
    order.review_request.destroy_if_without_products if order.review_request.present?

    OpenStruct.new ({
       object:           order.review_request,
       wrapper:          nil,
       id_from_provider: nil
    })
  end

  private

  def sync_order_transaction_items(order_wrapper, order)
    already_present_product_ids = order.transaction_items.map{ |ti| ti.reviewable_type == Product.name ? ti.reviewable_id : nil }.compact

    order_wrapper.product_ids.each do |product_id_from_provider|
      product = @store.products.find_by id_from_provider: product_id_from_provider
      service_result_product = self.product(id_from_provider: product_id_from_provider) unless product.present?
      product = service_result_product.object if service_result_product

      if product.present?
        next if already_present_product_ids.include? product.id
        TransactionItem.create(reviewable: product, customer: order.customer, order: order)
      end
    end
    order.save
    order = @store.orders.find_by_id(order.id)

    order.transaction_items.with_products.without_reviews.each do |transaction_item|
      transaction_item.destroy unless order_wrapper.product_ids.map(&:to_s).include? transaction_item.product.id_from_provider.to_s
    end

  end

end
