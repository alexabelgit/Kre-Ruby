require 'test_helper'

module Payments
  class ChargebeeRecurringChargeServiceTest < ActiveSupport::TestCase

    describe '#hosted_page' do

      let(:user) { create :user }
      let(:store) { create :store, user: user }
      let(:bundle) { create :bundle, store: store }
      let(:subscription) { create :subscription, bundle: bundle }
      subject { described_class.new }

      setup do
        plan_name = OpenStruct.new(chargebee_id: 'hc_essential')
        stub(bundle).plan_name { plan_name }
      end

      let(:sample_hosted_page) {
        OpenStruct.new id: "bK3bJRs4S1snQRWBAr8H7IyBcdnhmIbj0",
                       type: "checkout_new",
                       url: "https://yourapp.chargebee.com/pages/v2/bK3bJRs4S1snQRWBAr8H7IyBcdnhmIbj0/checkout"
      }

      let(:sample_hosted_page_result) {
        OpenStruct.new hosted_page: sample_hosted_page
      }

      test 'generates checkout page for given subscription' do
        fake_class(ChargeBee::HostedPage, checkout_new: sample_hosted_page_result)
        result = subject.hosted_page user, bundle, subscription

        assert_equal sample_hosted_page, result
      end
    end

    private

    def create_bundle_with_two_addons
      bundle = create :bundle, store: store

      create :addon_price, bundle: bundle
      create :addon_price, bundle: bundle
    end
  end
end
