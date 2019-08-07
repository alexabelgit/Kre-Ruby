class Medium < ApplicationRecord

  belongs_to :mediable, polymorphic: true, touch: true

  delegate :store, to: :mediable

  enum media_type: [ :image,   :video                ]
  enum status:     [ :pending, :published, :archived ]

  before_create       :auto_publish
  after_create_commit :assign_cloudinary_image

  scope :with_cloudinary_id, -> { where('cloudinary_public_id IS NOT NULL') }

  def public_url(format: nil)
    return if cloudinary_public_id.nil?
    if image?
      ApplicationController.helpers.cl_image_path(cloudinary_public_id, format: format)
    elsif video?
      ApplicationController.helpers.cl_video_thumbnail_path(cloudinary_public_id, format: format)
    end
  end

  def public_id_for_ovelay
    cloudinary_public_id.gsub('/', ':')
  end

  def migrate_to_review!(review, skip_cloudinary_and_recognition: false)
    update_attributes(mediable_id: review.id, mediable_type: review.class.name)

    unless skip_cloudinary_and_recognition
      rename_on_cloudinary
      enqueue_aws_rekognition
    end
  end

  protected

  def auto_publish
    self.status = 'published' if store.settings(:reviews).auto_publish_media.to_b
  end

  def assign_cloudinary_image
    if cloudinary_public_id.start_with?('unassigned-media/')
      rename_on_cloudinary
      enqueue_aws_rekognition
    end
  end

  def rename_on_cloudinary
    result = Cloudinary::Uploader.rename(cloudinary_public_id,
                                         assign_cloudinary_folder,
                                         overwrite: true,
                                         resource_type: media_type)
    if assign_cloudinary_folder != result['public_id']
      Raven.capture_message("Cloudinary public ID error", { level: 'error', extra: { assign_cloudinary_folder: assign_cloudinary_folder,
                                                                                     result: result,
                                                                                     store: store.as_json,
                                                                                     mediable: mediable.as_json,
                                                                                     medium: self.as_json
                                                                                   }})
    end
    update_attributes(cloudinary_public_id: result['public_id'])
  end

  def assign_cloudinary_folder
    "stores/#{store.hashid}/#{mediable.class.name.downcase.pluralize}/#{mediable.hashid}/media/#{media_type.to_s.pluralize}/#{self.hashid}"
  end

  def enqueue_aws_rekognition
    AwsRekognitionWorker.perform_async(id) if image?
  end
end
