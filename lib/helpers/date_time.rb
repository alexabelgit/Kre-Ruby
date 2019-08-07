class DateTime
  def self.civil_with_timezone(a, b, c, d, e)
    return false unless Date.valid_date?(a, b, c)
    self.civil(a, b, c, d, e, 0, Rational((Time.zone.tzinfo.current_period.utc_offset / 1800), 48))
  end
end
