class ArchiveProductWorker
    include Sidekiq::Worker
  
    sidekiq_options queue: :default, retry: 10
  
    def perform(store_id, product_id_from_provider)
      store = Store.find_by id: store_id
      return if store.blank? || !store.installed?

      product = store.products.find_by_id_from_provider product_id_from_provider
      return if product.blank?
      i = {status: 'archived', suppressed: true}.merge(product: product)
      ::Products::UpdateProduct.run i

      SyncProductsWorker.perform_uniq_in(12.hours, store_id)      
    end
  end
  