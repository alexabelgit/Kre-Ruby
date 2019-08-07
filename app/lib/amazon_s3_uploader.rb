class AmazonS3Uploader
  attr_reader :bucket, :s3
  DOWNLOADS_BUCKET =  Rails.configuration.aws.downloads_bucket.freeze
  CLOUDFRONT_DOMAIN = Rails.configuration.aws.cloudfront_domain.freeze

  def initialize
    @s3 = Aws::S3::Resource.new(region: 'us-east-1')
    @bucket = DOWNLOADS_BUCKET
  end

  def upload_text(file_name, text)
    object = s3.bucket(bucket).object(file_name)
    result = object.upload_stream do |write_stream|
      write_stream << text
    end

    if result
      OpenStruct.new status: :success, url: cloudfront_url(object.key)
    else
      OpenStruct.new status: :error, object: object
    end
  end

  private
  def cloudfront_url(key)
    "#{CLOUDFRONT_DOMAIN}/#{key}"
  end
end