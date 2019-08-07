class DeleteImagesJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?
    return if store.active?
    return unless store.user.deleted?

    store.products.each do |product|
      Cloudinary::Uploader.destroy(product.featured_image.my_public_id)
      product.update_attributes(featured_image: nil)
    end

    store.media.each do |medium|
      Cloudinary::Uploader.destroy(medium.cloudinary_public_id)
      medium.update_attributes(cloudinary_public_id: nil)
    end
  end

end
