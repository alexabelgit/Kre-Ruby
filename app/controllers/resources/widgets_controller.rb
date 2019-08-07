class Resources::WidgetsController < ResourcesController

  before_action  :set_store

  def index
    respond_to do |format|
      format.json {
        render json: (@store.storefront_active? ? {
                   js: {
                       url: widgets_js
                   },
                   css: {
                       url:   widgets_css,
                       theme: @store.theme_css
                   },
                   custom_css: {
                       enabled: @store.custom_stylesheet_active,
                       code: Base64.encode64(@store.custom_stylesheet_code)
                   }
               } : false)
      }
    end
  end

  private

  def set_store
    @store = Store.find_by_id_from_provider_or_hashid(params[:store_id])
  end

  def widgets_css
    if Rails.env.development?
      asset_path('widgets.css')
    else
      Cloudinary::Assets.process_storefront_asset(original_file: asset_path('widgets.css'),
                                                   digest:       asset_digest('widgets', 'css'),
                                                   key:          'widgets',
                                                   name:         'hc-style',
                                                   extension:    'css',
                                                   prefix:       params[:prefix])
    end
  end

  def widgets_js
    if Rails.env.development?
      asset_path('integrations/static/front.js')
    else
      Cloudinary::Assets.process_storefront_asset(original_file: asset_path('integrations/static/front.js'),
                                                  digest:        asset_digest('integrations/static/front', 'js'),
                                                  key:           'widgets',
                                                  name:          'hc-script',
                                                  extension:     'js')
    end
  end

end
