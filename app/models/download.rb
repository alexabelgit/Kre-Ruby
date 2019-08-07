class Download < ApplicationRecord
  belongs_to :store

  enum status: [:pending, :processing, :ready, :error]

  scope :ordered, -> { order('created_at DESC') }
  scope :expired, -> { where('expired_at < ?', DateTime.current) }

  before_create :set_expiration_date

  DOWNLOAD_LIFETIME = 7.days.freeze


  def signed_cookies
    config = Rails.configuration.aws
    signer = Aws::CloudFront::CookieSigner.new key_pair_id: config.cloudfront_key_pair_id,
                                               private_key: config.cloudfront_private_key
    signer.signed_cookie url, expires: 7.days.from_now
  end

  private

  def set_expiration_date
    self.expired_at = created_at + DOWNLOAD_LIFETIME if expired_at.blank?
  end
end
