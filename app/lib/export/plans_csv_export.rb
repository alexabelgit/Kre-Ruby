module Export
  class PlansCsvExport
    attr_reader :plans

    CSV_HEADERS = ["plan[id]", "plan[name]", "plan[invoice_name]", "plan[period]",
                   "plan[period_unit]", "plan[price]", "plan[currency_code]", "plan[pricing_model]",
                   "plan[free_quantity]",
                   "plan[enabled_in_hosted_pages]", "plan[enabled_in_portal]", "plan[taxable]",
                   "plan[is_shippable]", "plan[status]" ].freeze

    def initialize(plans)
      @plans = plans
    end

    def generate
      CSV.generate(headers: true) do |csv|
        csv << CSV_HEADERS

        plans.map do |plan|
          csv << [
              plan.chargebee_id, plan.chargebee_id&.titleize || plan.name, plan.name.capitalize, 1, 'month',
              plan.price_in_cents, 'USD', 'flat_fee', 0,
              true, true, true, false, 'active'
          ]
        end
      end
    end
  end
end
