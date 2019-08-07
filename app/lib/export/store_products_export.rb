module Export
  class StoreProductsExport

    HEADERS = ["id", "name", "url", "image_url", "HelpulCrowd ID"].freeze

    def initialize(store)
      @store = store
    end

    def create_report
      products = @store.products.map{|p| [p.id_from_provider, p.name, p.url, p.featured_image.small.url, p.id]}

      CSV.generate(headers: true) do |csv|
        csv << HEADERS

        products.each do |entry|
          csv << entry
        end
      end
    end
  end
end