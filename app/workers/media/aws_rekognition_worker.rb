class AwsRekognitionWorker
  include Sidekiq::Worker
  include CloudinaryHelper
  sidekiq_options queue: :default, retry: 3

  def perform(medium_id)
    require 'open-uri'

    medium = Medium.find_by_id(medium_id)
    return unless medium.present?
    return unless medium.image?

    url = cl_image_path(medium.cloudinary_public_id)
    return if url.blank?

    # Image dimensions should be of minimum 80x80 for aws rekognition
    dimensions = FastImage.size(url)
    if dimensions.present? && (dimensions[0] < 80 || dimensions[1] < 80)
      if dimensions.each_with_index.min[1] == 0
        url = cl_image_path(medium.cloudinary_public_id, width: 80, crop: :fit)
      else
        url = cl_image_path(medium.cloudinary_public_id, height: 80, crop: :fit)
      end
    end

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
