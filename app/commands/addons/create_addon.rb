module Addons
  class CreateAddon < ApplicationCommand
    include PersistAddon

    def execute
      addon = Addon.new inputs.except(:prices)

      if addon.save
        update_addon_prices(addon, prices)
      else
        errors.merge!(addon.errors)
      end
      addon
    end

    def to_model
      Addon.new
    end
  end
end
