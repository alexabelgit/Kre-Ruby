module Addons
  class UpdateAddon < ApplicationCommand
    include PersistAddon
    object :addon

    def execute
      addon.name = name if name?
      addon.description = description if description?
      addon.state = state if state?

      if addon.save
        update_addon_prices(addon, prices)
      else
        errors.merge!(addon.errors)
      end
      addon
    end

    def to_model
      addon
    end
  end
end
