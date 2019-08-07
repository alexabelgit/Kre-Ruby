module Deprecatable
  extend ActiveSupport::Concern

  included do
    scope :latest, -> { where('deprecated_at IS NULL') }
    scope :deprecated, -> { where('deprecated_at IS NOT NULL') }
  end

  def status
    actual? ? :actual : :deprecated
  end

  def actual?
    !deprecated?
  end

  def deprecated?
    deprecated_at.present?
  end

  def deprecate!
    update_attributes!(deprecated_at: Time.zone.now)
  end
end
