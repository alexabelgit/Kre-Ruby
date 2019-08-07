module Stores
  module BillableTest
    extend ActiveSupport::Concern

    included do
      teardown do
        Flipper.enable :billing
      end

      describe '#can_be_billed?' do
        test 'depends on whether Flipper enables it for store or not' do
          Flipper.disable :billing

          Flipper[:billing].enable @store
          assert @store.can_be_billed?

          Flipper[:billing].disable @store
          refute @store.can_be_billed?
        end
      end

      describe '.need_send_trial_ending_email' do
        def create_billable_store_with_trial_ending_soon
          create :store, ecommerce_platform: EcommercePlatform.shopify, trial_ends_at: 3.days.from_now
        end

        test 'excludes stores that cannot be billed' do
          Flipper.disable :billing

          not_billable_store = create :store, ecommerce_platform: EcommercePlatform.custom, trial_ends_at: 3.days.from_now
          Flipper[:billing].disable not_billable_store

          billable_store = create_billable_store_with_trial_ending_soon
          Flipper[:billing].enable billable_store

          stores_to_send_emails = Store.need_send_trial_ending_email
          assert_equal [billable_store], stores_to_send_emails
        end

        test 'excludes store that are paid' do
          paid_store = create_billable_store_with_trial_ending_soon
          bundle = create :bundle, store: paid_store, state: :active
          create :subscription, :active, bundle: bundle

          non_paid_store = create_billable_store_with_trial_ending_soon

          assert_equal [non_paid_store], Store.need_send_trial_ending_email
        end

        test 'exludes stores that already got such email' do
          already_got_email = create_billable_store_with_trial_ending_soon
          already_got_email.update_settings(:billing, trial_ending_email_sent: true)

          not_got_email_yet = create_billable_store_with_trial_ending_soon

          assert_equal [not_got_email_yet], Store.need_send_trial_ending_email
        end
      end

      describe '.need_send_trial_finished_email' do
        def create_billable_store_with_trial_finished
          create :store, ecommerce_platform: EcommercePlatform.shopify, trial_ends_at: 1.hour.ago
        end

        test 'excludes stores that cannot be billed' do
          not_billable_store = create :store, ecommerce_platform: EcommercePlatform.custom, trial_ends_at: Time.current
          billable_store = create_billable_store_with_trial_finished

          stores_to_send_emails = Store.need_send_trial_finished_email
          assert_equal [billable_store], stores_to_send_emails
        end

        test 'excludes store that are paid' do
          paid_store = create_billable_store_with_trial_finished
          bundle = create :bundle, store: paid_store, state: :active
          subscription =  create :subscription, :active, bundle: bundle

          non_paid_store = create_billable_store_with_trial_finished

          assert_equal [non_paid_store], Store.need_send_trial_finished_email
        end

        test 'exludes stores that already got such email' do
          already_got_email = create_billable_store_with_trial_finished
          already_got_email.update_settings(:billing, trial_finished_email_sent: true)

          not_got_email_yet = create_billable_store_with_trial_finished

          assert_equal [not_got_email_yet], Store.need_send_trial_finished_email
        end
      end

      describe '.need_send_grace_period_email' do
        def create_billable_store_with_grace_period_finishing
          create :store, ecommerce_platform: EcommercePlatform.shopify, trial_ends_at: 5.days.ago
        end

        test 'excludes stores that cannot be billed' do
          not_billable_store = create :store, ecommerce_platform: EcommercePlatform.custom, trial_ends_at: 3.days.ago
          billable_store = create_billable_store_with_grace_period_finishing

          stores_to_send_emails = Store.need_send_grace_period_email
          assert_equal [billable_store], stores_to_send_emails
        end

        test 'excludes store that are paid' do
          paid_store = create_billable_store_with_grace_period_finishing
          bundle = create :bundle, store: paid_store, state: :active
          subscription = create :subscription, :active, bundle: bundle

          non_paid_store = create_billable_store_with_grace_period_finishing

          assert_equal [non_paid_store], Store.need_send_grace_period_email
        end

        test 'exludes stores that already got such email' do
          already_got_email = create_billable_store_with_grace_period_finishing
          already_got_email.update_settings(:billing, grace_period_email_sent: true)

          not_got_email_yet = create_billable_store_with_grace_period_finishing

          assert_equal [not_got_email_yet], Store.need_send_grace_period_email
        end
      end

      describe '#live?' do
        let(:store) { create :store, trial_ends_at: 20.days.from_now }

        test 'store is live when its on trial' do
          stub(store).trial? { true }
          assert store.live?
        end

        test 'store is live during grace period' do
          stub(store).grace_period? { true }
          assert store.live?
        end

        test 'store is live when it has active subscription' do
          bundle = create :bundle, state: 'active', store: store
          create :subscription, :active, bundle: bundle
          assert store.live?
        end
      end

      describe '#paid?' do
        test 'store is paid when it has at least one active subscription' do
          @store = create :store
          bundle = create :bundle, state: 'active', store: @store
          create :subscription, :active, bundle: bundle
          assert @store.reload.paid?
        end
      end

      describe '#trial?' do
        test 'store is not on trial when its paid' do
          stub(@store).paid? { true }
          refute @store.trial?
        end

        test 'store is not on trial when trial expired' do
          stub(@store).trial_ended? { true }
          refute @store.trial?
        end

        test 'store is not on trial if it had active subscription before' do
          stub(@store).had_subscription_before? { true }
          refute @store.trial?
        end
      end

      describe '#grace_period?' do
        test 'store is not on grace period if it was paid' do
          stub(@store).paid? { true }
          refute @store.grace_period?
        end

        test 'store is not on grace period if its trial is not over' do
          stub(@store).trial_ended? { false }
          refute @store.grace_period?
        end

        test 'store is not on grace period is grace period ended' do
          @store = build :store
          stub(@store).grace_period_ended? { true }
          refute @store.grace_period?
        end
      end

      describe '#trial_ending?' do
        test 'store should be on trial' do
          stub(@store).trial? { false }
          refute @store.trial_ending?
        end

        test 'trial should end soon' do
          @store.trial_ends_at = 2.days.from_now
          assert @store.trial_ending?
        end
      end

      describe "#subscription_expired?" do
        setup do
          @expired_store = create :store
        end

        test 'store should not have active subscription at the moment' do
          outdated_bundle = create :bundle, state: :outdated, store: @expired_store
          subscription = create :subscription, state: :cancelled, bundle: outdated_bundle

          bundle = create :bundle, :active, store: @expired_store
          subscription = create :subscription, :active, bundle: bundle

          refute @expired_store.subscription_expired?
        end

        test 'store should not have terminating subscription' do
          outdated_bundle = create :bundle, state: :outdated, store: @expired_store
          subscription = create :subscription, state: :cancelled, bundle: outdated_bundle

          bundle = create :bundle, :active, store: @expired_store
          subscription = create :subscription, bundle: bundle, state: :non_renewing, expired_at: 1.month.from_now

          refute @expired_store.subscription_expired?
        end

        test 'store should have at least one cancelled subscription' do
          outdated_bundle = create :bundle, state: :outdated, store: @expired_store
          subscription = create :subscription, state: :cancelled, bundle: outdated_bundle

          assert @expired_store.subscription_expired?
        end
      end

      describe '#suspended?' do
        test 'never suspend stores without billing implemented' do
          stub(@store).can_be_billed? { false }
          refute @store.suspended?
        end

        test 'store is suspended when its not paid and grace period is over' do
          stub(@store).can_be_billed? { true }

          stub(@store).paid? { false }
          stub(@store).grace_period_ended? { true }
          assert @store.suspended?

          stub(@store).grace_period_ended? { false }
          refute @store.suspended?
        end

        test 'store is always live when its paid' do
          stub(@store).can_be_billed? { true }
          stub(@store).paid? { true }
          stub(@store).grace_period_ended? { true }

          refute @store.suspended?
        end
      end
    end
  end
end
