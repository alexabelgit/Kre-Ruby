module Callbacks
  class ChargebeeController < CallbacksController

    def create
      case params[:event_type]
      when 'subscription_created'
        subscription = fetch_subscription

        if subscription.present?
          respond_with_success
        else
          subscription_not_found
        end
      when 'subscription_cancelled'
        subscription = fetch_subscription
        if subscription
          cancel_subscription subscription
          respond_with_success
        else
          subscription_not_found
        end
      when 'subscription_changed'
        subscription = fetch_subscription
        if subscription
          if sync_subscription_with_chargebee?(subscription)
            sync_subscription subscription
          end
          respond_with_success
        else
          subscription_not_found
        end
      when 'subscription_renewed'
        subscription = fetch_subscription
        if subscription
          renew_subscription subscription
          respond_with_success
        else
          subscription_not_found
        end
      when 'payment_failed'
        subscription = fetch_subscription
        if subscription
          mark_subscription_as_dunning subscription
          respond_with_success
        else
          subscription_not_found
        end
      when 'payment_succeeded'
        subscription = fetch_subscription
        if subscription
          process_payment subscription

          respond_with_success
        else
           subscription_not_found
        end
      else
        puts 'Do not know how to handle this webhook'
        respond_with_success
      end
    end

    private

    def sync_subscription_with_chargebee?(subscription)
      last_updated = dig_subscription 'updated_at'
      subscription.updated_at < last_updated && !subscription.processing?
    end

    def sync_subscription(subscription)
    end

    def subscription_id
      dig_subscription('id') || dig_transaction('subscription_id')
    end

    def fetch_subscription
      return nil if subscription_id.nil?
      Subscription.find_by id_from_provider: subscription_id
    end

    def process_payment(subscription)
      if subscription.has_debt?
        has_subscription_data = params.dig('content', 'subscription')
        if has_subscription_data
          due_invoices_count = dig_subscription 'due_invoices_count'
          if due_invoices_count.to_i.zero?
            Subscriptions::ClearDebt.run subscription: subscription
          end
        else
          amount_due = params.dig('content', 'invoice', 'amount_due').to_i
          if amount_due.zero?
            Subscriptions::ClearDebt.run subscription: subscription
          end
        end
      end
      update_payment_date subscription
    end

    def update_payment_date(subscription)
      last_payment_at = to_datetime params.dig('content', 'transaction', 'date')
      Subscriptions::UpdateSubscription.run subscription: subscription, last_payment_at: last_payment_at
    end

    def renew_subscription(subscription)
      updated_at = to_datetime dig_subscription('updated_at')
      next_billing_at = to_datetime dig_subscription('next_billing_at')

      Subscriptions::RenewSubscription.run subscription: subscription, updated_at: updated_at, next_billing_at: next_billing_at
    end

    def cancel_subscription(subscription)
      cancelled_at = to_datetime dig_subscription('cancelled_at')
      cancel_reason = dig_subscription 'cancel_reason'
      inputs = {
        subscription: subscription,
        cancelled_at: cancelled_at,
        cancellation_reason: cancel_reason,
        cancelled_by_customer: false
      }
      inputs.merge! due_data(subscription)
      Subscriptions::CancelSubscription.run inputs
    end

    def mark_subscription_as_dunning(subscription)
      due_since = to_datetime dig_subscription('due_since')
      inputs = {
        dunning_start_date: DateTime.current,
        subscription: subscription
      }.merge(due_data(subscription))
      Subscriptions::MarkAsDunning.run inputs
    end

    def due_data(subscription)
      due_since = to_datetime dig_subscription('due_since')
      {
        due_invoices_count: dig_subscription('due_invoices_count'),
        total_due: dig_subscription('total_dues'),
        due_since: due_since
      }
    end

    def subscription_not_found
      report_missing_subscription
      render json: { status: :subscription_not_found }, status: 404
    end

    def to_datetime(unix_time)
      Time.at(unix_time.to_i).to_datetime
    end

    def report_missing_subscription
      ahoy.track :subscription_missing, subscription_id: subscription_id, event_type: :global
    end

    def respond_with_success
      render json: { status: :success }, status: 200
    end

    def dig_subscription(key)
      params.dig('content', 'subscription', key)
    end

    def dig_transaction(key)
      params.dig('content', 'transaction', key)
    end
  end
end
