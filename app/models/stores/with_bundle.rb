module Stores
  module WithBundle
    extend ActiveSupport::Concern

    included do
      has_many :bundles,                  dependent: :destroy
      has_many :subscriptions, through: :bundles
      scope :with_active_subscription, -> { joins(bundles: :subscription).where('subscriptions.state': [:active, :non_renewing]) }
    end

    def active_bundle
      Rails.cache.fetch [self, 'active_bundle'] do
        bundles.active.last
      end
    end

    def active_subscription
      Rails.cache.fetch [self, 'active_subscription'] do
        active_bundle&.subscription
      end
    end

    def had_subscription_before?
      subscriptions.where(state: [:active, :cancelled, :non_renewing, :archived, :suspended, :reactivating]).present?
    end

    def draft_bundle
      Rails.cache.fetch [self, 'draft_bundle'] do
        bundles.draft.last
      end
    end

    # only relevant when subscription got suspended due to problems
    # with payments
    def disabled_bundle
      Rails.cache.fetch [self, 'disabled_bundle'] do
        bundles.disabled.last
      end
    end

    def disabled_subscription
      Rails.cache.fetch [self, 'disabled_subscription'] do
        disabled_bundle&.subscription
      end
    end
  end
end
