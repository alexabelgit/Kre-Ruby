class NotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && value > DateTime.current
      record.errors.add attribute, (options[:message] || "cannot be in future") # TODO message should be set via I18n, in all supported languages
    end
  end
end
