module Stores
  module EnabledInSettings
    extend ActiveSupport::Concern

    def recaptcha_enabled?
      settings(:global).recaptcha.to_b
    end

    def review_slider_c2a_enabled?
      settings(:widgets).review_slider_c2a_enabled.to_b
    end

    def show_non_rated_products?
      settings(:widgets).product_rating_show_not_rated.to_b
    end

    def auto_publish_reviews?
      settings(:reviews).auto_publish.to_b
    end

    def auto_publish_media?
      settings(:reviews).auto_publish_media.to_b
    end

    def media_collage_in_social_posts?
      settings(:reviews).media_collage_in_social_posts.to_b
    end

    def easy_reviews?
      settings(:reviews).easy_reviews.to_b
    end

    def authenticated_reviews?
      settings(:reviews).authenticated_reviews.to_b
    end

    def media_reviews_enabled?
      settings(:reviews).media_reviews.to_b
    end

    def questions_enabled?
      settings(:questions).enabled.to_b
    end
  end
end
