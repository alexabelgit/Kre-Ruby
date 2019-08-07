class UpgradeBundlePresenter < BundlePresenter

  def initialize(bundle, old_bundle, view = ActionView::Base)
    @bundle     = bundle
    @view       = view
    @old_bundle = old_bundle
  end

  def one_time_charges?
    changed_addons.present?
  end

  def prorata_days
    billing_date = old_bundle&.subscription&.next_billing_at
    return 0 unless billing_date

    days = (billing_date - DateTime.current)/1.day
    days.round
  end

  def one_time_charges_total
    charges = added_addons.sum do |addon|
      price = bundle.addon_prices.find { |p| p.addon == addon }
      price.prorated_price(prorata_days)
    end

    credits = removed_addons.sum do |addon|
      price = old_bundle.addon_prices.find { |p| p.addon == addon }
      price.prorated_price(prorata_days)
    end

    view.number_to_currency in_dollars(charges - credits)
  end

  def added_addons
    bundle.addons - old_bundle.addons
  end

  def added_addons_prices
    Rails.cache.fetch [bundle, 'prorated-charges'] do
      added_addons.map do |addon|
        price          = bundle.addon_prices.find { |p| p.addon == addon }
        prorated_price = price.prorated_price(prorata_days)
        in_dollars     = view.number_to_currency in_dollars(prorated_price)
        { name: addon.name, price: in_dollars }
      end
    end
  end

  def removed_addons_credits
    Rails.cache.fetch [old_bundle, 'prorated-credits'] do
      removed_addons.map do |addon|
        price          = old_bundle.addon_prices.find { |p| p.addon == addon }
        prorated_price = price.prorated_price(prorata_days)
        in_dollars     = view.number_to_currency(-in_dollars(prorated_price))
        { name: addon.name, price: in_dollars }
      end
    end
  end

  def removed_addons
    old_bundle.addons - bundle.addons
  end

  def changed_addons
    added_addons | removed_addons
  end

  private

  attr_reader :bundle, :old_bundle, :view
end
