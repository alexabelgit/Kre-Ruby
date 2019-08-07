class Resources::LemonstandController < ResourcesController

  before_action  :set_store, only: [:index, :storefront_scripts]

  def index
    respond_to do |format|
      format.json {
        render json: (@store.storefront_active? ? {
                   js: {
                       url: Cloudinary::Assets.process_storefront_asset(original_file: asset_path('integrations/lemonstand/front.js'),
                                                                        digest:        asset_digest('integrations/lemonstand/front', 'js'),
                                                                        key:           'js',
                                                                        name:          'hc-script',
                                                                        extension:     'js')
                   },
                   css: {
                       url: Cloudinary::Assets.process_storefront_asset(original_file: asset_path('integrations/lemonstand/front.css'),
                                                                        digest:        asset_digest('integrations/lemonstand/front', 'css'),
                                                                        key:           'css',
                                                                        name:          'hc-style',
                                                                        extension:     'css'),
                       theme: @store.theme_css
                   },
                   widgets: {
                       sidebar: @store.settings(:widgets).sidebar.to_b
                   },
                   suppressions: @store.products.suppressed.map(&:id_from_provider).map(&:to_s),
                   store_id:     @store.hashid
               } : false)
      }
    end
    response.headers['X-Frame-Options'] = 'ALLOWALL' # TODO this is temporary
  end

  def storefront_scripts
    if @store.present?
      respond_to do |format|
        format.js
      end
    else
      not_found
    end
  end

  private

  def set_store
    @store = Store.find_by_id_from_provider_or_hashid(params[:store_id])
  end
end
