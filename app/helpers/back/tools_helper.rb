module Back::ToolsHelper

  def step_heading_class(status)
    case status
    when :comlete
      'hc-color__success'
    when :warning
      'hc-color__warning'
    end
  end

  def shopify_link(path)
    "https://#{@shopify_store_domain}/#{path}"
  end

  def product_exists?
    Sync::ShopifyService.new(store: @store).product_exists?
  end

  def storefront_open?
    Sync::ShopifyService.new(store: @store).storefront_open?
  end

  def widget_code_embedded?(widget)
    widget = "#{widget}_in_use".to_sym
    @store.settings(:widgets).send(widget).to_b
  end

  def embeddables
    %w(stylesheet product_summary product_tabs product_rating)
  end

  def manual_step_class(widget)
    if widget == :stylesheet
      widget_code_embedded?(widget) ? "success" : "danger"
    else
      widget_code_embedded?(widget) ? "success" : "warning"
    end
  end

  def manual_step_icon(widget)
    if widget == :stylesheet
      widget_code_embedded?(widget) ? "check-circle md success" : "exclamation-circle md danger"
    else
      widget_code_embedded?(widget) ? "check-circle md success" : "exclamation-circle md warning"
    end
  end

  def theme_supported?
    Shopify::Utils.auto_inject_supported?(store: @store)
  end

end
