module BackHelper
  def current_store
    current_user.store
  end

  def stamp_product_if_archived_or_hidden(product)
    # This helper is used acroos multiple controllers in back namespace so it's
    # placed in BackHelper instead of Back::ProductsHelper
    if product.hidden?
      hc_icon 'exclamation-triangle', class: 'product-suppress-icon', title: 'This product is hidden and review requests are not sent for it'
    elsif product.archived?
      hc_icon 'archive', class: 'product-suppress-icon', title: 'This product has been archived automatically if deleted in the store or manually in HelpfulCrowd'
    end
  end

  def stamp_discount_coupon_if_archived(discount_coupon)
    # This helper is used acroos multiple controllers in back namespace so it's
    # placed in BackHelper instead of Back::ProductsHelper
    if discount_coupon.archived?
      hc_icon 'exclamation-triangle', class: 'discount-coupon-archive-icon', title: 'This discount coupon is archived and no customer can receive it'
    end
  end

  def chat_trigger(text = "Message", html_class: nil)
    link_to(text, 'javascript:', class: "intercom #{html_class if html_class}")
  end

  def widget_mockup_image(widget)
    widget = widget.to_s
    url = if widget == 'product_tabs'
            suffix = current_store.settings(:design).rounded.to_b ? 'rounded' : 'squared'
            t("back.widgets.#{widget}.mockup_image_url.#{suffix}")
          else
            t("back.widgets.#{widget}.mockup_image_url")
          end
    image_tag url
  end

  def connect_store_path(store)
    return connect_back_stores_path if store.nil?

    case store.provider
    when 'custom'
      connect_with_custom_website_back_stores_path
    when 'ecwid'
      connect_with_ecwid_back_stores_path
    when 'lemonstand'
      reconnect_with_lemonstand_back_stores_path
    when 'shopify'
      connect_with_shopify_back_stores_path
    end
  end
end
