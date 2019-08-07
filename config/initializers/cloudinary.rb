config = ActiveSupport::OrderedOptions.new

config.cloudinary_url = Rails.env.test? ? "cloudinary://test:test@test" : ENV['CLOUDINARY_URL']

CLOUDINARY_REGEXP = /\/\/(?<api_key>.+)\:(?<api_secret>.+)\@(?<cloud_name>\w+)/.freeze

if config.cloudinary_url
  match = config.cloudinary_url.match CLOUDINARY_REGEXP
  match.named_captures&.each { |k, v| config.send("#{k}=", v) } if match
end

Rails.configuration.cloudinary = config
