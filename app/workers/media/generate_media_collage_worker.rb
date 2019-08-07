# not used anymore. We used to pre-generate media collage on Cloudinary for faster fetch by facebook
# however I don't thing it's reasonable since url is generate instantly anyway and facebook metatag could wait a bit
# keeping this up just in case we return to pre-generation again
class GenerateMediaCollageWorker
  include Sidekiq::Worker
  require 'open-uri'
  sidekiq_options queue: :default, retry: 3

  def perform(review_id)
    review = Review.find(review_id)
    return unless review.present?
    return unless review.media_collage?

    open("#{review.media_collage}").read
  end
end
