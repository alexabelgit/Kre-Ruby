module Stores
  module ActivatedAddons
    extend ActiveSupport::Concern

    included do
      has_many :enabled_addons
    end

    def addons_feature_enabled?
      Flipper[:addons].enabled?(self)
    end

    def active_addons
      return [] unless addons_feature_enabled?

      Rails.cache.fetch(self) do
        return Addon.active if all_addons_enabled_mode?

        ids = enabled_addons.pluck(:enabled_addon_id).to_a
        Addon.where(id: ids)
      end
    end

    private

    def all_addons_enabled_mode?
      !can_be_billed? || trial? || grace_period?
    end

    # Always true if addons feature disabled for this store or globally
    # Always true if store cannot be billed or in trial/grace period
    # False if addon name is nil
    # Otherwise checks whether store has this addon active
    def has_addon?(addon_name)
      return true unless addons_feature_enabled?

      return false unless addon_name
      return true if all_addons_enabled_mode?

      active_addons.select { |active| active.name == addon_name }.present?
    end

  end
end
