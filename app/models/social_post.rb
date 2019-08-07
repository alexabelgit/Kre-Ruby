class SocialPost < ApplicationRecord

  before_create  :publish
  before_destroy :unpublish

  belongs_to :postable, polymorphic: true, touch: true

  enum provider: [:facebook, :instagram, :pinterest, :twitter]

  delegate :store, :product, to: :postable # TODO ~ product may be nil and all methods should be aware of this

  validates_uniqueness_of :uid, scope: :provider

  def link
    # TODO this is a temporary method for ADMIN only. We should add an attribute link to db and save links when posts are created
    case self.provider
    when 'facebook'
      "http://facebook.com/#{self.store.settings(:social_accounts).facebook_page_id}/posts/#{self.uid.split('_').last}"
    when 'twitter'
      "http://twitter.com/#{self.store.settings(:social_accounts).twitter_username}/status/#{self.uid}"
    end
  end

  protected

  def seo_thumbnail_url
    return self.product.seo_friendly_url if Rails.env.development?
    Rails.application.routes.url_helpers.send("front_product_#{postable.class.name.downcase}_url",
                                              self.store.hashid,
                                              self.postable.product.hashid,
                                              self.postable,
                                              host:  Rails.configuration.urls_config.app_host,
                                              redirect: true,
                                              protocol: 'https')
  end

  def post_on_facebook
    result = false
    if self.postable.published? && self.store.facebook_active?
      page_graph = store.koala_page
      page_graph.get_object('me')
      page_graph.get_connection('me', 'feed')

      message  = self.postable.facebook_post_body
      response = page_graph.put_wall_post(message, { link: self.seo_thumbnail_url })

      if response.present? && response['id']
        self.uid = response['id']
        result = true
      end
    end
    throw :abort unless result

    result
  end

  def post_on_twitter
    result = false
    if self.postable.published? && self.store.twitter_profile_connected?
      twitter  = self.store.twitter_client
      tweet    = self.postable.tweet_body
      tweet    = "#{tweet.to_char_a.shift(112).join}..." if tweet.length > 116
      tweet   += " #{self.seo_thumbnail_url}"

      if Twitter::TwitterText::Validation.parse_tweet(tweet)[:valid]
        response = twitter.update(tweet)
        if response.present? && response.respond_to?(:id) && self.postable.social_posts.twitter.where(uid: response.id.to_s).empty?
          self.uid = response.id.to_s
          result = true
        end
      end
    end
    throw :abort unless result

    result
  end

  def publish
    post_on_facebook if self.facebook?
    post_on_twitter  if self.twitter?
  end

  def unpublish
    begin
      case self.provider
      when 'facebook'
        self.store.koala_page.delete_object(self.uid)
      when 'twitter'
        self.store.twitter_client.destroy_tweet(self.uid)
      end
    rescue => e
      Rails.logger.error { "#{e.message} #{e.backtrace.join("\n")}" }
    end
  end
end
