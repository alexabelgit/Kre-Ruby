class Plan
  class UpgradeCharge
    include Priceable

    def initialize(new_plan:, previous_plan:)
      @new_plan = new_plan
      @previous_plan = previous_plan
    end

    def amount
      return 0 unless valid?

      price_difference = new_plan.price_in_cents - previous_plan.price_in_cents
      price_difference
    end

    def description
      return '' unless valid?

      "Upgrade from '#{previous_plan.name}' plan to '#{new_plan.name}' plan"
    end

    private

    def valid?
      new_plan.present? && previous_plan.present? && new_plan > previous_plan
    end

    attr_reader :new_plan, :previous_plan
  end
end
