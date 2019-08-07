module Stores
  class AnonymizeStore < ApplicationCommand
    object :store

    array :customer_ids, default: [] do
      integer
    end

    def execute
      customers = store.customers.non_anonymous

      customers = customers.where(id_from_provider: customer_ids) if customer_ids.present?

      results = customers.map(&:anonymize!)
      results.all?
    end
  end
end
