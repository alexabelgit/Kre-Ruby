class AwsRekognitionJob < ApplicationJob
  include CloudinaryHelper
  queue_as :default

  ### SIDEKIQED

  def perform(medium_id)
    require 'open-uri'

    medium = Medium.find_by_id(medium_id)
    return unless medium.present?
    return unless medium.image?

    url = cl_image_path(medium.cloudinary_public_id)
    return if url.blank?

    aws_client   = Aws::Rekognition::Client.new(access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
    img          = open(url)
    aws_response = aws_client.detect_moderation_labels({ image: { bytes: img.read } })

    aws_response.moderation_labels.each do |moderation_label|
      medium.update_attributes(status: 'archived', explicit: true) if moderation_label.confidence >= 50.0
    end

    medium.update_attributes(moderated: true, moderation_result: aws_response.moderation_labels)
    BackMailer.explicit_media(medium.mediable).deliver_in(5.minutes) if medium.mediable.media.image.where(moderated: false).empty? && medium.mediable.media.image.where(explicit: true).any?
  end
end
