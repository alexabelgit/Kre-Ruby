namespace :order_refactor do

  desc 'Send Admin Reports'
  task reporting: :environment do

    include Priceable

    reports = []
    report_data = Reports::MonthlyRequests.new.create_report 1, 1
    report = {variables: [{heading: report_data.heading}, {rows: report_data.rows}], template: 'admin/reporting/monthly_requests'}
    reports << report

    report_data = Reports::MonthlyReviews.new.create_report 1, 1
    report = {variables: [{heading: report_data.heading}, {rows: report_data.rows}], template: 'admin/reporting/monthly_reviews'}
    reports << report

    report_data = Reports::MonthlyQuestions.new.create_report 1, 1
    report = {variables: [{heading: report_data.heading}, {rows: report_data.rows}], template: 'admin/reporting/monthly_questions'}
    reports << report

    subscriptions = Subscription.where(state: [:active, :non_renewing])
                         .joins(:bundle)
                         .includes(:initial_bundle,
                                   { bundle:  [:plans,
                                               { store: [:store_subscription_usage, :ecommerce_platform] } ]
                                   })

    keys = ['Store id', 'Store name', 'Store url', 'Plan name', 'Billing cycle start', 'Billing cycle end',
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

    values = values.compact

    report = {variables: [{keys: keys}, {values: values}], template: 'admin/reporting/billing'}
    reports << report


    emails = ['niko@helpfulcrowd.com', 'sandro@helpfulcrowd.com', 'vlad@helpfulcrowd.com', 'scott@helpfulcrowd.com' ]
    emails.each do |email|
      AdminMailer.reports(email, reports).deliver_now!
      STDOUT.puts "sent reports to #{email}"
    end
  end
end
