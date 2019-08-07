module Products
  class CreateProduct < ApplicationCommand
    object :store

    string :name, default: nil
    string :id_from_provider, default: nil
    string :url, default: nil

    boolean :suppressed, default: nil
    symbol :status, default: nil
    string :storefront_availability, default: nil

    date_time :last_synced_at, default: nil
    date_time :image_last_synced_at, default: nil

    array :skus, default: [] do string end

    file :featured_image, default: nil
    boolean :overwrite_featured_image, default: nil

    boolean :initiated_by_user, default: true

    SYNCED_PRODUCT_ERROR = "Your products are synced with your e-commerce platform and you cannot add or delete them manually".freeze

    def execute
      product = Product.new given_inputs.except(:initiated_by_user)
      if initiated_by_user && !store.manages_products?
        errors.add(:product, SYNCED_PRODUCT_ERROR)
        return product
      end

      unless product.save
        errors.merge!(product.errors)
      end
      product
    end
  end
end
