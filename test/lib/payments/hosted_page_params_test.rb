require 'test_helper'

module Payments
  class HostedPageParamsTest < ActiveSupport::TestCase

    let(:user) { create :user, email: 'test@user.com', first_name: 'Test', last_name: 'User' }
    let(:store) { create :store, user: user, legal_name: 'Disney LLC' }
    let(:plan) { create :plan, chargebee_id: '123' }
    let(:bundle) { create :bundle, store: store }

    let(:subscription) { create :subscription, bundle: bundle, id_from_provider: 'subscription_1' }

    before do
      create :bundle_item, price_entry: plan, bundle: bundle
    end

    describe '#checkout_params' do
      test 'contains basic customer info' do
        subject = described_class.new user, bundle, subscription
        customer_info = subject.checkout_params[:customer]

        assert_equal 'test@user.com', customer_info[:email]
        assert_equal 'Test', customer_info[:first_name]
        assert_equal 'User', customer_info[:last_name]
        assert_equal 'Disney LLC', customer_info[:company]
        assert_equal store.id, customer_info[:cf_store_id]
        assert_nil customer_info[:phone]
      end

      test 'contains phone name if store has phone number' do
        store.phone = '+79091234567'

        subject = described_class.new user, bundle, subscription
        customer_info = subject.checkout_params[:customer]
        assert_equal '+79091234567', customer_info[:phone]

      end

      test 'truncates phone number so it wont exceed 45 chars' do
        store.phone = "1" * 55
        subject = described_class.new user, bundle, subscription
        customer_info = subject.checkout_params[:customer]
        assert_equal '111111111111111111111111111111111111111111...', customer_info[:phone]
      end

      test 'addons list should be empty' do
        subject = described_class.new user, bundle, subscription
        assert_empty subject.checkout_params[:addons]
      end

      test 'subscription params contain selected plan' do
        subject = described_class.new user, bundle, subscription
        subscription_params = subject.checkout_params[:subscription]
        assert_equal plan.chargebee_id, subscription_params[:plan_id]
      end

      describe 'when reactivating subscription' do
        test 'subscription params contain subscription id' do
          subject = described_class.new user, bundle, subscription, reactivate: true
          subscription_params = subject.checkout_params[:subscription]
          assert_equal 'subscription_1', subscription_params[:id]
        end
      end
    end
  end
end