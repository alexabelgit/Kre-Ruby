module Reports
  class MonthlyRequests

    CSV_HEADER = ['Store Id', 'Store Name', 'Store Url', 'Plan name', 'Signed up', 'Products count', 'Uninstall date', 'Active Token', 'Total requests', 'From eCommerce', 'Is Scheduled'].freeze

    def create_report(year, month)
      heading = CSV_HEADER + ReviewRequest.statuses.keys

      filter_date = DateTime.new(year, month)
      first_date  = review_request_first_date filter_date
      date_array  = (Date.new(first_date.year, first_date.month)..DateTime.current.to_date).select {|d| d.day == 1}
      heading += date_array.map { |d| "#{Date::MONTHNAMES[d.month]} #{d.year}"}

      grouped_requests = group_requests filter_date
      rows = csv_rows grouped_requests, date_array

      OpenStruct.new heading: heading, rows: rows
    end

    private

    def review_request_first_date(date_since)
      ReviewRequest.where("created_at >= ?", date_since).order(created_at: :asc).first.created_at
    end

    def grouping
      '(extract(year from review_requests.created_at),
      extract(month from review_requests.created_at)),
      review_requests.status,
      stores.id,
      (orders.id IS NOT NULL),
      (review_requests.scheduled_for IS NOT NULL)'
    end

    def select
      'COUNT(review_requests.id) AS requests,
      review_requests.status AS request_status,
      (review_requests.scheduled_for IS NOT NULL) AS scheduled,
      (orders.id IS NOT NULL) AS from_provider,
      stores.id AS store_id,
      MAX(stores.name) AS store_name,
      MAX(stores.url) AS store_url,
      MAX(store_summaries.plan_name) AS plan_name,
      MAX(stores.created_at) AS signed_up,
      MAX(stores.products_count) AS products_count,
      (CASE WHEN (MAX(stores.installed_at) IS NOT NULL) THEN MAX(stores.uninstalled_at) ELSE NULL END) AS uninstalled_at,
      (MAX(stores.access_token) <> \'\') AS active_token,
      extract(year from review_requests.created_at) AS year, extract(month from review_requests.created_at) AS month'
    end

    def group_requests(since_date)
      grouped_requests = ReviewRequest.where("review_requests.created_at >= ?", since_date)
                                      .left_outer_joins(:order)
                                      .joins(customer: :store)
                                      .joins('INNER JOIN store_summaries ON store_summaries.store_id = stores.id')
                                      .select(select)
                                      .group(grouping)

      grouped_requests = grouped_requests.map do |g|
        {
          store_id: g.store_id,
          store_name: g.store_name,
          store_url: g.store_url,
          plan_name: g.plan_name,
          signed_up: g.signed_up,
          products_count: g.products_count,
          uninstalled_at: g.uninstalled_at,
          requests: g.requests,
          status: g.request_status,
          scheduled: g.scheduled.to_b,
          from_provider: g.from_provider.to_b,
          active_token:  g.active_token.to_b,
          year_month: "#{Date::MONTHNAMES[g.month.to_i]} #{g.year.to_i}"
        }
      end

      grouped_requests.group_by { |e| [e[:store_id], e[:store_name], e[:store_url], e[:plan_name], e[:signed_up], e[:products_count], e[:uninstalled_at], e[:active_token]] }
    end

    def csv_rows(grouped_requests, date_array)
      grouped_requests.map do |grouped_request|
        store_line       = grouped_request.first
        grouped_by_store = grouped_request.last
        total_requests = 0
        requests_array = []
        status_counts  = { }
        ReviewRequest.statuses.keys.each do |status_key|
          status_counts[:"#{status_key}"] = 0
        end

        from_provider_count = 0
        scheduled           = 0

        date_array.each do |date|
          grouped_by_months = grouped_by_store.select{|g| g[:year_month] == "#{Date::MONTHNAMES[date.month]} #{date.year}"}

          status_counts_by_date  = { }
          ReviewRequest.statuses.keys.each do |status_key|
            status_counts_by_date[:"#{status_key}"] = 0
            grouped_by_months_and_statuses = grouped_by_months.select{|g| g[:status] == ReviewRequest.statuses[status_key]}

            grouped_by_months_and_statuses.each do |gms|
              status_counts_by_date[:"#{status_key}"] += gms[:requests]
              status_counts[:"#{status_key}"] += gms[:requests]
              from_provider_count += gms[:requests] if gms[:from_provider]
              scheduled           += gms[:requests] if gms[:scheduled]
            end
          end

          sum_requests_by_date = status_counts_by_date.values.sum
          requests_array << sum_requests_by_date
          total_requests += sum_requests_by_date
        end

        store_line << total_requests
        store_line << from_provider_count
        store_line << scheduled
        store_line += status_counts.values

        store_line += requests_array
        store_line
      end
    end
  end
end
