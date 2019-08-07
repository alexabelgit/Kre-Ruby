class AddonPresenter

  delegate :name, :description, to: :addon

  def initialize(addon, bundle, view)
    @addon = addon
    @bundle = bundle
    @view = view
  end

  def current_price
    addon_price&.price_in_dollars
  end

  def new_subscription?
    bundle.persisted?
  end

  def enabled?
    bundle.contains?(addon)
  end

  def checkbox_name
    "addons[#{addon.slug}]"
  end

  def price_id
    addon_price&.id
  end

  private

  def addon_price
    @addon_price ||= addon.latest_price(bundle.platform)
  end

  attr_reader :addon, :bundle, :view
end
