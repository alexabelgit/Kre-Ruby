require 'test_helper'

module Callbacks
  class ChargebeeControllerTest < ActionDispatch::IntegrationTest

    let(:subscription_id) { '12345' }

    setup do
      Timecop.freeze
    end

    def build_subscription_params(options = {})
      subscription_params = { 'subscription' => options }
      { 'content' => subscription_params }
    end

    describe 'subscription_created' do
      let(:params) { { event_type: 'subscription_created' } }

      describe 'when subscription already exits' do
        setup do
          @subscription = create :subscription, id_from_provider: subscription_id
        end

        test 'responds with success' do
          params.merge! build_subscription_params(id: subscription_id)
          post callbacks_chargebee_url, params: params
          assert_response 200
        end
      end

      describe 'when subscription does not exist' do
        test 'responds with not found' do
          params.merge! build_subscription_params(id: subscription_id)
          post callbacks_chargebee_url, params: params
          assert_response 404
        end
      end
    end

    describe 'subscription_cancelled' do
      let(:params) { { event_type: 'subscription_cancelled'} }

      describe 'when subscription exists' do
        let(:cancelled_at) { 3.hours.ago }
        let(:cancelled_at_unix_time) { cancelled_at.to_time.to_i }

        setup do
          @subscription = create :subscription, :active, id_from_provider: subscription_id
        end

        test 'stops subscription renewal' do
          params.merge! build_subscription_params(id: subscription_id, cancelled_at: cancelled_at_unix_time )
          post callbacks_chargebee_url, params: params

          assert @subscription.reload.cancelled?
          assert_equal cancelled_at.to_s, @subscription.cancelled_on.to_s
        end

        test 'responds with success' do
          params.merge! build_subscription_params(id: subscription_id, cancelled_at: cancelled_at )
          post callbacks_chargebee_url, params: params
          assert_response 200
        end
      end

      describe 'when subscription does not exist' do
        test 'responds with not found' do
          params.merge! build_subscription_params(id: subscription_id)
          post callbacks_chargebee_url, params: params
          assert_response 404
        end
      end
    end

    describe 'payment_failed' do
      let(:params) { { event_type: 'payment_failed'} }
      let(:due_since) { 1.day.ago.to_datetime.to_i }
      describe 'when subscription exists' do
        setup do
          @subscription = create :subscription, :active, id_from_provider: subscription_id
        end

        test 'marks subscription as dunning' do
          params.merge! build_subscription_params(id: subscription_id, due_since: due_since, due_invoices_count: 1, total_dues: 299)
          post callbacks_chargebee_url, params: params

          assert @subscription.reload.dunning?
        end
      end

      describe 'when subscription does not exist' do
        test 'responds with not found' do
          params.merge! build_subscription_params(id: subscription_id)
          post callbacks_chargebee_url, params: params
          assert_response 404
        end
      end
    end
  end
end
