module Admin
  class ReportingController < AdminController
    include Priceable
    include ActionController::Live
    include CsvHeaders

    def billing
      subscriptions = Subscription.where(state: [:active, :non_renewing])
                           .joins(:bundle)
                           .includes(:initial_bundle,
                                     { bundle:  [:plans,
                                                 { store: [:store_subscription_usage, :ecommerce_platform] } ]
                                     })

      @keys = ['Store id', 'Store name', 'Store url', 'Plan name', 'Billing cycle start', 'Billing cycle end',
              'Orders in current billing cycle', 'Plan price', 'Overages', 'Ecommerce platform']
      values = subscriptions.find_each.map do |subscription|
        store = subscription.store
        orders_this_cycle = store.orders_in_current_billing_cycle

        plan = subscription.active_plan
        next if plan.blank?
        plan_price = plan.price_in_dollars

        billing_cycle = subscription.current_billing_cycle

        charge = Plan::OverageCharge.new subscription
        overages = in_dollars(charge.amount)

        [store.hashid, store.name, store.url,
         plan.name, billing_cycle.first, billing_cycle.last,
         orders_this_cycle, plan_price, overages, store.provider]
      end

      @values = values.compact

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] = 'attachment; filename="billing.xlsx"'
        end
      end
    end

    def monthly_requests(year: 1, month: 1)
      report = Reports::MonthlyRequests.new.create_report year, month
      @heading = report.heading
      @rows = report.rows

      respond_to do |format|
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename="Monthly Requests By Store.xlsx"'
        }
      end
    end

    def monthly_reviews(year: 1, month: 1)
      report = Reports::MonthlyReviews.new.create_report year, month
      @heading = report.heading
      @rows = report.rows

      respond_to do |format|
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename="Monthly Reviews By Store.xlsx"'
        }
      end
    end

    def monthly_questions(year: 1, month: 1)
      report = Reports::MonthlyQuestions.new.create_report year, month
      @heading = report.heading
      @rows = report.rows

      respond_to do |format|
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename="Monthly Questions By Store.xlsx"'
        }
      end
    end

    def export_stores_to_csv
      set_csv_headers
      Export::StoresCsvExport.new.write_to_stream response.stream
    end
  end
end
