Rails.configuration.aws = ActiveSupport::OrderedOptions.new
aws = Rails.configuration.aws
aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
aws.cloudfront_key_pair_id = ENV['CLOUDFRONT_KEY_PAIR_ID']
aws.cloudfront_private_key = ENV['CLOUDFRONT_PRIVATE_KEY']
aws.downloads_bucket = ENV['AWS_S3_DOWNLOADS_BUCKET']
aws.cloudfront_domain = ENV['CLOUDFRONT_DOMAIN']


