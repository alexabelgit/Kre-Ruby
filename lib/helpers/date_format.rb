class DateFormat
  HASH =
    {
      :'mm/dd/yyyy' => {string_format: "%m/%d/%Y", select_format: [:month, :day, :year]},
      :'mm/dd/yy'   => {string_format: "%m/%d/%y", select_format: [:month, :day, :year]},
      :'dd/mm/yyyy' => {string_format: "%d/%m/%Y", select_format: [:day, :month, :year]},
      :'dd/mm/yy'   => {string_format: "%d/%m/%y", select_format: [:day, :month, :year]},
      :'yyyy/mm/dd' => {string_format: "%Y/%m/%d", select_format: [:year, :month, :day]},
      :'mm-dd-yyyy' => {string_format: "%m-%d-%Y", select_format: [:month, :day, :year]},
      :'mm-dd-yy'   => {string_format: "%m-%d-%y", select_format: [:month, :day, :year]},
      :'dd-mm-yyyy' => {string_format: "%d-%m-%Y", select_format: [:day, :month, :year]},
      :'dd-mm-yy'   => {string_format: "%d-%m-%y", select_format: [:day, :month, :year]},
      :'yyyy-mm-dd' => {string_format: "%Y-%m-%d", select_format: [:year, :month, :day]},
      :'mm.dd.yyyy' => {string_format: "%m.%d.%Y", select_format: [:month, :day, :year]},
      :'mm.dd.yy'   => {string_format: "%m.%d.%y", select_format: [:month, :day, :year]},
      :'dd.mm.yyyy' => {string_format: "%d.%m.%Y", select_format: [:day, :month, :year]},
      :'dd.mm.yy'   => {string_format: "%d.%m.%y", select_format: [:day, :month, :year]},
      :'yyyy.mm.dd' => {string_format: "%Y.%m.%d", select_format: [:year, :month, :day]}
    }.freeze

  def self.list
    HASH.keys
  end

  def self.string_format(key)
    HASH[key.to_sym][:string_format]
  end

  def self.select_format(key)
    HASH[key.to_sym][:select_format]
  end
end
