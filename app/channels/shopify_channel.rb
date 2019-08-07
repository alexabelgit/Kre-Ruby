class ShopifyChannel < ApplicationCable::Channel
  def subscribed
    stream_from "shopify-#{current_user.hashid}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
