module SelectOptions
  extend ActiveSupport::Concern
  include ActionView::Helpers::FormOptionsHelper

  def ecommerce_platforms_select_options(current_platform = EcommercePlatform.shopify)
    platforms = EcommercePlatform.all.map { |platform| [platform.name, platform.id] }
    options_for_select platforms, current_platform.id
  end

end
