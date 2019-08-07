class Suppression < ApplicationRecord
  ## Assosiactions
  belongs_to :customer, required: false
  belongs_to :store

  ## Callbacks
  after_create :turn_off_marketing_preferences
  after_destroy :turn_on_marketing_preferences

  ## Enums
  enum source: {
    by_customer: 0,
    by_merchant: 1
  }

  ## Scopes
  scope :latest, -> { order(created_at: :desc) }

  ## Validations
  validates_presence_of   :email, :source
  validates_uniqueness_of :email, scope: [:store_id, :source]

  private

  def turn_off_marketing_preferences
    MarketingPreferencesWorker.perform_async store.id, customer.id, false if sync_marketing_preferences?
  end

  def turn_on_marketing_preferences
    MarketingPreferencesWorker.perform_async store.id, customer.id, true if sync_marketing_preferences?
  end

  def sync_marketing_preferences?
    customer.present? && store.present? && store.shopify?
  end

end
