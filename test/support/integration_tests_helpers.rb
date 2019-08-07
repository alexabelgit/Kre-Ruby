module IntegrationTestsHelper

  def pause
    $stderr.write 'Paused. Press enter to continue'
    $stdin.gets
  end

  def with_longer_timeout
    Capybara.default_max_wait_time = 30
    yield
    Capybara.default_max_wait_time = 2
  end

  def sign_in_user(authentication_key, password)
    visit '/users/sign_in'
    fill_in 'user_authentication_key', with: authentication_key
    fill_in 'user_password', with: password
    click_on 'Sign in with email'
    assert_content 'Helpful dashboard'
  end

  def sign_in_via_shopify_oauth(store)
    visit '/sign-in-with-shopify'
    store_handle = Shopify::UrlSanitizer.extract_shop_handle(store.domain)
    OmniAuth.config.add_mock(:shopify, {
                               uid: @store.id_from_provider,
                               credentials: { token: @store.access_token } } )


    fill_in 'shop', with: store_handle
    within '.auth-form' do
      click_on 'Sign in'
    end
  end

  def init_plans_only
    shopify = create :ecommerce_platform, name: 'shopify'
    ecwid = create :ecommerce_platform, name: 'ecwid'

    [shopify, ecwid].each do |platform|
      create :plan, ecommerce_platform: platform, name: 'Essential', price_in_cents: 500
      create :plan, ecommerce_platform: platform, name: 'Grow', price_in_cents: 1000
    end
  end


  def init_platforms_plans_and_addons
    shopify = create :ecommerce_platform, name: 'shopify'
    create :plan, ecommerce_platform: shopify, name: 'Essential'
    init_package_discounts shopify

    ecwid = create :ecommerce_platform, name: 'ecwid'
    create :plan, ecommerce_platform: ecwid
    init_package_discounts ecwid

    addons = ['Product groups', 'Unlimited requests', 'Media reviews']
    addons.each do |name|
      addon = Addon.create name: name, state: 'active'
      [shopify, ecwid].each do |platform|
        AddonPrice.create addon: addon, price_in_cents: 799, ecommerce_platform: platform
      end
    end
  end

  def init_package_discounts(platform)
    create :package_discount, addons_count: 2, discount_percents: 10, ecommerce_platform: platform
    create :package_discount, addons_count: 3, discount_percents: 15, ecommerce_platform: platform
  end
end
