class SeedBilling
  include Priceable

  def run
    platforms = setup_ecommerce_platforms
    setup_products_based_plans(platforms)
    setup_orders_based_plans(platforms)
  end

  def setup_migration_plans
    setup_ecommerce_platforms

    [@ecwid, @shopify].each do |platform|
      path = "#{Rails.root}/db/seeds/#{platform.name}_migration_plans.yaml"
      setup_products_plans_from_file platform, path
    end
  end

  private

  def setup_ecommerce_platforms
    platforms = EcommercePlatform::SUPPORTED_PLATFORMS.map do |name|
      EcommercePlatform.find_or_create_by name: name
    end

    @ecwid, @shopify, @custom, @lemonstand = platforms
    platforms
  end

  def setup_products_based_plans(platforms)
    platforms.each do |platform|
      path = "#{Rails.root}/db/seeds/#{platform.name}.yaml"
      setup_products_plans_from_file platform, path
    end
  end

  def setup_products_plans_from_file(platform, seed_file)
    return if platform.lemonstand? # lemonstand is not working anymore but we haven't removed it from supported platforms yet

    product_plans = YAML.load_file(seed_file)['products'].with_indifferent_access

    product_plans.each do |slug, data|
      next if Plan.find_by(slug: slug, ecommerce_platform: platform, pricing_model: :products)

      params = data.slice(:name, :price_in_cents, :min_products_limit, :max_products_limit)
      params[:ecommerce_platform] = platform
      params[:description] = products_plan_description(data)
      params[:pricing_model] = :products
      params[:is_secret] = data[:is_secret].presence.to_b
      params[:slug] = slug
      params[:chargebee_id] = data[:chargebee_id] unless platform.shopify?

      Plan.create params
    end
  end

  def setup_orders_based_plans(platforms)
    plans = [
      { name: 'Helpful',   price: 0,    quota: 20,  extension_price: nil, extended_quota: nil, is_secret: true  },
      { name: 'Handful',   price: 500,  quota: 50,  extension_price: 250, extended_quota: 50,  is_secret: false, overages_limit_in_cents: 1000 },
      { name: 'Boxful',    price: 1000, quota: 200, extension_price: 200, extended_quota: 50,  is_secret: false, popular: true, overages_limit_in_cents: 2000 },
      { name: 'Bucketful', price: 2000, quota: 500, extension_price: 150, extended_quota: 50,  is_secret: false, overages_limit_in_cents: 3000 },
      { name: 'Plentiful', price: nil,  quota: nil, extension_price: nil, extended_quota: nil, is_secret: false }
    ]

    platforms.flat_map do |platform|
      plans.each do |plan|
        slug   = plan[:name].downcase
        params = {
          name:                     plan[:name],
          description:              orders_plan_description(plan.slice(:quota, :extension_price, :extended_quota)),
          slug:                     slug,
          ecommerce_platform:       platform,
          price_in_cents:           plan[:price],
          orders_limit:             plan[:quota],
          extension_price_in_cents: plan[:extension_price],
          extended_orders_limit:  plan[:extended_quota],
          is_secret:                plan[:is_secret],
          popular:                  plan.fetch(:popular, false)
        }
        if platform.shopify?
          params[:overages_limit_in_cents] = plan[:overages_limit_in_cents]
        else
          params[:chargebee_id] = slug unless platform.shopify?
        end
        Plan.find_or_create_by params
      end
    end

    setup_affiliate_plan_for_shopify
  end

  def setup_affiliate_plan_for_shopify
    params = {
      name: 'Affiliate',
      description: 'Plan for Shopify development stores. 500 requests per month for free',
      ecommerce_platform: @shopify,
      price_in_cents: 0,
      slug: 'affiliate',
      orders_limit: 500,
      extension_price_in_cents: 0,
      extended_orders_limit: 0,
      is_secret: true,
      popular: false
    }
    Plan.find_or_create_by params
  end

  def orders_plan_description(quota:, extension_price:, extended_quota:)
    return unless extension_price

    dollars = in_dollars_as_currency extension_price
    "#{quota} in-plan orders each month. #{dollars} for bundle of #{extended_quota} out-of-plan orders"
  end

  def products_plan_description(data)
    price = in_dollars data[:price_in_cents]
    lower_limit = data[:min_products_limit]
    upper_limit = data[:max_products_limit]
    if upper_limit
      "$#{price} monthly for stores with up to #{upper_limit} products"
    else
      "$#{price} monthly for stores with #{lower_limit} and more products"
    end
  end
end
