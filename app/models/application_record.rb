class ApplicationRecord < ActiveRecord::Base
  include Hashid::Rails

  self.abstract_class = true

  class << self

    def find_by_id_or_hashid(id)
      decoded_id = decode_id id
      decoded_id.present? ? (find_by(id: decoded_id) || find_by!(id: id)) : find_by!(id: id)
    rescue Hashids::InputError
      find_by! id: id
    end

    def find_by_id_from_provider_or_hashid(id)
      decoded_id = decode_id id
      decoded_id.present? ? (find_by(id: decoded_id) || find_by!(id_from_provider: id)) : find_by!(id_from_provider: id)
    rescue Hashids::InputError
      find_by! id_from_provider: id
    end


    def humane_enum_name(enum_name, enum_value)
      I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
    end
  end
end
