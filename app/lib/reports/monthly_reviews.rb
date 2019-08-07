module Reports
  class MonthlyReviews
    def create_report(year, month)
      heading = ['Store Id', 'Store Name', 'Store Url', 'Plan name', 'Signed up', 'Uninstall date', 'Active Token', 'Total reviews']

      filter_date = DateTime.new(year, month)
      first_date  = Review.where("created_at >= ?", filter_date).order(created_at: :asc).first.created_at
      date_array  = (Date.new(first_date.year, first_date.month)..DateTime.current.to_date).select {|d| d.day == 1}
      heading += date_array.map{|d| "#{Date::MONTHNAMES[d.month]} #{d.year}"}

      grouping = '(extract(year from reviews.created_at), extract(month from reviews.created_at)), stores.id'
      select   = 'COUNT(reviews.id) AS reviews_count,
                  stores.id AS store_id, MAX(stores.name) AS store_name, MAX(stores.url) AS store_url,
                  MAX(store_summaries.plan_name) AS plan_name,
                  MAX(stores.created_at) AS signed_up,
                  (CASE WHEN (MAX(stores.installed_at) IS NOT NULL) THEN MAX(stores.uninstalled_at) ELSE NULL END) AS uninstalled_at,
                  (MAX(stores.access_token) <> \'\') AS active_token,
                  extract(year from reviews.created_at) AS year, extract(month from reviews.created_at) AS month'
      grouped_reviews = Review.where("reviews.created_at >= ?", filter_date)
                                     .joins(customer: :store)
                                     .joins('INNER JOIN store_summaries ON store_summaries.store_id = stores.id')
                                     .select(select)
                                     .group(grouping)

      grouped_reviews = grouped_reviews.map {|g| {store_id: g.store_id, store_name: g.store_name,
                                                  store_url: g.store_url, plan_name: g.plan_name,
                                                  signed_up: g.signed_up, uninstalled_at: g.uninstalled_at,
                                                  reviews: g.reviews_count, active_token: g.active_token || 'FALSE',
                                                  year_month: "#{Date::MONTHNAMES[g.month.to_i]} #{g.year.to_i}"}}
      grouped_reviews = grouped_reviews.group_by {|e| [e[:store_id], e[:store_name], e[:store_url], e[:plan_name], e[:signed_up], e[:uninstalled_at], e[:active_token]]}
      rows = grouped_reviews.map do |grouped_review|
        store_line = grouped_review.first
        grouped    = grouped_review.last
        total_reviews = 0
        reviews_array = []
        date_array.each do |date|
          from_array = grouped.select{|g| g[:year_month] == "#{Date::MONTHNAMES[date.month]} #{date.year}"}
          reviews    = (from_array.present? ? from_array.first[:reviews] : 0)
          reviews_array << reviews
          total_reviews += reviews
        end
        store_line << total_reviews
        store_line += reviews_array
        store_line
      end
      OpenStruct.new heading: heading, rows: rows
    end
  end
end
