module Emails
  class PlanExceededPresenter < BasePresenter

    delegate :products_based_billing?, to: :store

    def plan_extensible?
      subscription.plan_extensible?
    end
  end
end