module Chargebee
  class ResponseParser
    def self.to_hash(chargebee_model)
      json = chargebee_model.to_json
      values = JSON.parse(json)['values']
      values.with_indifferent_access
    end
  end
end
