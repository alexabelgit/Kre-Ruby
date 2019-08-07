module Front::ProductsHelper
  def recent_reviews_of(product, count = 12)
    product.reviews.published.limit(count)
  end

  def media_class_name(count, limit_count, total_count)
    element_class = (count <= limit_count-1 ? 'hc-media__medium--visible' : '')
    element_class + (count == limit_count-1 && total_count > limit_count ? ' hc-media__medium--last-visible' : '')
  end

  def extract_media(reviews)
    reviews.flat_map(&:published_media)
  end

  def extract_media_types(media)
    media.map(&:media_type)
  end

  def image_count(review)
    count = review.published_images.count
    return if count == 0
    icon = hc_icon "camera"
    text = t('media_gallery.images', scope: 'front.widgets.products.tabs.reviews', count: count)
    "<div class='hc-media__image-count'>#{icon} #{text}</div>".html_safe
  end

  def video_count(review)
    count = review.published_videos.count
    return if count == 0
    icon = hc_icon "video-camera"
    text = t('media_gallery.videos', scope: 'front.widgets.products.tabs.reviews', count: count)
    "<div class='hc-media__video-count'>#{icon} #{text}</div>".html_safe
  end
end
