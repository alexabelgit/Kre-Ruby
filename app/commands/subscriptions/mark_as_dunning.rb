module Subscriptions
  class MarkAsDunning < ApplicationCommand
    object :subscription

    integer :total_due
    date_time :due_since
    integer :due_invoices_count
    date_time :dunning_start_date

    def execute
      result = subscription.update total_due: total_due,
                                   due_since: due_since,
                                   due_invoices_count: due_invoices_count,
                                   dunning_start_date: dunning_start_date

      unless result
        errors.merge!(subscription.errors)
      end

      subscription
    end
  end
end
