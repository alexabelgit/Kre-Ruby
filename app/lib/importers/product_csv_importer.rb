module Importers
  class ProductCsvImporter
    attr_reader :store

    IMPORT_PRODUCT_FIELDS = OpenStruct.new(product_id_field: 'id',
                                           product_name_field: 'name',
                                           product_url_field: 'url',
                                           product_image_url_field: 'image_url').freeze

    REQUIRED_PRODUCT_FIELDS = %w[id name url].freeze

    delegate :product_id_field, :product_name_field, :product_url_field, :product_image_url_field,
             to: :IMPORT_PRODUCT_FIELDS

    def self.valid_csv?(column_names)
      (REQUIRED_PRODUCT_FIELDS - column_names).empty?
    end

    def initialize(store)
      @store = store
    end

    def import(csv)
      Searchkick.callbacks(false) do
        csv.reverse_each.map(&method(:import_row)).compact
      end
    end

    private

    def import_row(row_data)
      product_info = product_attributes row_data

      existing_product = store.products.find_by id_from_provider: product_info.id_from_provider

      result = existing_product ? update_product(existing_product, product_info) : create_new_product(product_info)

      result ? nil : row_data
    end

    def create_new_product(info)
      attributes = info.to_h.except(:featured_image_url).merge(store_id: store.id, skip_reindex_children: true)
      product = Product.create attributes
      return false unless product.persisted?

      set_image product, info.featured_image_url
    end

    def update_product(product, info)
      attributes = info.to_h.slice(:name, :url)
      result = product.update attributes
      return false unless result

      set_image(product, info.featured_image_url) if info.featured_image_url
    end

    def set_image(product, image_url)
      return unless image_url
      Products::SetFeaturedImage.run(product: product, image_url: image_url)
    end

    def product_attributes(row_data)
      OpenStruct.new id_from_provider: row_data[product_id_field],
                     name: row_data[product_name_field],
                     url: row_data[product_url_field],
                     featured_image_url: row_data[product_image_url_field]
    end
  end
end