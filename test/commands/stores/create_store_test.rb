require 'test_helper'

module Stores
  class CreateStoreTest < ActiveSupport::TestCase
    setup do
      @shopify = EcommercePlatform.shopify
      create :plan, ecommerce_platform: @shopify
    end

    let(:user) { create :user }
    let(:params) { {
                     id_from_provider: "1234",
                     url: "http://store_url.com",

                     name: 'some store',
                     legal_name: 'legal name',
                     provider: "shopify",
                     user: user
                   }}

    test 'executes successfully' do
      outcome = described_class.run params
      assert outcome.valid?
    end

    test 'creates store' do
      assert_difference 'Store.count', +1 do
        described_class.run params
      end
    end

  end
end
