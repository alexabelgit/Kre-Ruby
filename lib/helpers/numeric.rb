# coding: utf-8
class Numeric
  def percent_of(n)
    return 0 if n.zero? || self.zero?

    value = (self * 100) / n.to_f
    value.to_i == value ? value.to_i : value
  end

  def seconds_to_gmt_dif
    sign    = self > 0 ? '+' : '-'
    seconds = self.abs
    hours   = (seconds / 3600).to_i.to_s
    minutes = ((seconds % 3600) / 60).to_i.to_s
    hours   = "0#{hours}" if hours.length == 1

    if minutes.length == 1
      if minutes == '0'
        minutes = "#{minutes}0"
      else
        minutes = "0#{minutes}"
      end
    end
    "#{sign}#{hours}:#{minutes}"
  end

  def to_stars
    res  = '★' * self.to_i
    res += (self - self.to_i >= 0.5 ? '★' : '☆') if self % 1 != 0
    res += '☆' * (5 - self).to_i
    res
  end

  def to_datetime
    DateTime.strptime(self.to_s, '%s').in_time_zone(Time.zone)
  end

end

class Integer
  N_BYTES = [42].pack('i').size
  N_BITS  = N_BYTES * 16
  MAX     = 2 ** (N_BITS - 2) - 1
  MIN     = -MAX - 1
end
