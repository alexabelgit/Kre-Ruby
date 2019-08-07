module Products
  class SetFeaturedImage < ApplicationCommand
    object :product

    string :image_url
    date_time :image_updated_at, default: nil

    def execute
      return if product.custom_image?
      return if product.featured_image? && !image_changed?

      params = { image_last_synced_at: DateTime.current, original_image_url: image_url, remote_featured_image_url: image_url }
      params.delete(:remote_featured_image_url) if Rails.env.test?

      product.update params
    end

    private

    def image_changed?
      timestamp_different = product.image_last_synced_at.present? && image_updated_at.present? && image_updated_at <= product.image_last_synced_at
      image_url_different =  product.original_image_url && product.original_image_url != image_url

      timestamp_different || image_url_different
    end
  end
end