require 'test_helper'

class BillingPagetest < ActionDispatch::IntegrationTest
  include IntegrationTestsHelper

  let(:email) { 'user@email.com' }
  let(:password) { 'password' }

  setup do
    use_javascript_driver
    init_plans_only

    @user = create :user, email: email, password: password, password_confirmation: password
  end

  describe 'when store platform does not have billing' do
    setup do
      custom_platform = create :ecommerce_platform, name: 'custom'
      @store = create :store, :installed, ecommerce_platform: custom_platform, user: @user
      bundle = create :bundle, store: @store
      create :bundle_item, bundle: bundle, price_entry: Plan.latest_price(@store.ecommerce_platform)
    end

    test 'user will see dummy billing page' do
      sign_in_user @user.authentication_key, password
      visit_billing_page

      assert_selector 'h1', text: 'Billing'
      assert_content 'We are currently in the process of changing payment gateway'
    end
  end

  describe 'when store platform has billing' do
    before do
      @store = create :shopify_store, :installed, user: @user, ecommerce_platform: EcommercePlatform.shopify

      bundle = create :bundle, store: @store
      create :bundle_item, bundle: bundle, price_entry: Plan.latest_price(@store.ecommerce_platform)
    end

    test 'user can see billing page when store can be billed' do
      sign_in_via_shopify_oauth @store
      visit_billing_page

      assert_selector 'h1', text: 'Billing'
    end
  end

  private

  def assert_no_current_subscription
    assert_content 'No active subscription'
  end

  def visit_billing_page
    visit '/'
    with_longer_timeout do
      click_on 'Settings'
      click_on 'Billing'
    end
  end
end
