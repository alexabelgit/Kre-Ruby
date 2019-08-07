class Resources::EcwidController < ResourcesController

  before_action :set_store, only: :index

  def index
    respond_to do |format|
      format.json {
        render json: (@store.storefront_active? ? {
                   js: {
                       url: Cloudinary::Assets.process_storefront_asset(original_file: asset_path('integrations/ecwid/front.js'),
                       digest:        asset_digest('integrations/ecwid/front', 'js'),
                       key:           'js',
                       name:          'hc-script',
                       extension:     'js')
                   },
                   css: {
                       url: Cloudinary::Assets.process_storefront_asset(original_file: asset_path('integrations/ecwid/front.css'),
                       digest:        asset_digest('integrations/ecwid/front', 'css'),
                       key:           "#{params[:html_id]}-#{params[:body_id]}",
                       name:          'hc-style',
                       extension:     'css',
                       prefix:        params[:prefix]),
                       theme: @store.theme_css
                   },
                   custom_css: {
                       enabled: @store.custom_stylesheet_active,
                       code: Base64.encode64(@store.custom_stylesheet_code)
                   },
                   widgets: {
                       sidebar:         @store.settings(:widgets).sidebar.to_b,
                       product_rating:  @store.settings(:widgets).product_rating_autoembed.to_b,
                       product_summary: @store.settings(:widgets).product_summary_autoembed.to_b,
                       product_tabs:    @store.settings(:widgets).product_tabs_autoembed.to_b
                   },
                   suppressions: @store.products.suppressed.pluck(:id_from_provider)
               } : false)
      }
    end
  end

  def storefront_scripts
    expires_in 15.minutes, public: true
    respond_to do |format|
      format.js
    end
  end

  private

  def set_store
    @store = Store.find_by_id_from_provider_or_hashid(params[:store_id])
  end
end
