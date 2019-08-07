class ActionDispatch::Request::Session

  def store_record(record, scope: nil)
    scope = record.class.name.downcase.to_sym unless scope.present?
    self[scope] ||= {}
    self[scope][record.id.to_s] = true
  end

  def validate_record?(record, scope: nil)
    scope = record.class.name.downcase.to_sym unless scope.present?
    self[scope] ||= {}
    !self[scope][record.id.to_s]
  end

end