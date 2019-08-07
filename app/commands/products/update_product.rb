module Products
  class UpdateProduct < ApplicationCommand
    object :product

    string :name, default: nil
    string :id_from_provider, default: nil
    string :url, default: nil

    boolean :suppressed, default: nil
    symbol :status, default: nil
    string :storefront_availability, default: nil

    date_time :last_synced_at, default: nil

    array :skus, default: [] do
      string
    end

    file :featured_image, default: nil
    boolean :overwrite_featured_image, default: nil

    boolean :initiated_by_user, default: true

    def execute
      if enabled_custom_image? && featured_image.nil?
        errors.add(:custom_image, "file has not been selected. Click 'Choose file' to upload image")
        return product
      end

      attributes_to_update = allowed_attributes

      if enabled_custom_image?
        attributes_to_update[:featured_image] = featured_image

        if switching_from_synced_to_custom?
          attributes_to_update[:synced_image_backup] = to_cloudinary_file(product.featured_image)
        end
      end

      switching_back_to_synced_image = product.custom_image? && product.synced_image_backup.present? &&
                                       disabled_custom_image? && !manages_products?

      unless product.update(attributes_to_update)
        errors.merge! product.errors
        return product
      end

      if switching_back_to_synced_image
        product.update featured_image: to_cloudinary_file(product.synced_image_backup), synced_image_backup: nil, image_last_synced_at: nil
        resync_product
      end

      product
    end

    private

    def enabled_custom_image?
      overwrite_featured_image.to_b
    end

    def disabled_custom_image?
      given?(:overwrite_featured_image) && overwrite_featured_image == false
    end

    def to_cloudinary_file(image)
      return nil unless image&.identifier

      Cloudinary::CarrierWave::StoredFile.new(image.identifier)
    end

    def resync_product
      SyncProductWorker.perform_async product.store_id, product.id_from_provider
    end

    def manages_products?
      product.store.manages_products?
    end

    def had_custom_image?
      product.custom_image? && synced_image_backup.present? && !manages_products?
    end

    def initiated_by_platform?
      !initiated_by_user
    end

    def allowed_attributes
      allowed_keys = %i[suppressed overwrite_featured_image status last_synced_at skus suppressed storefront_availability]
      allowed_keys += %i[name id_from_provider url featured_image] if manages_products? || initiated_by_platform?
      given_inputs.slice(*allowed_keys)
    end

    def switching_from_synced_to_custom?
      enabled_custom_image? && featured_image.present? && !product.custom_image? && product.featured_image.identifier
    end
  end
end
