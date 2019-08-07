require 'csv'

class Array
  def humanize_values
    self.map{|x| [x.first, x.last.to_s.humanize]}
  end
  def humanize_keys
    self.map{|x| [x.first.to_s.humanize, x.last]}
  end


  def self.csv_to_array(file_data)
    csv = false
    begin
      csv = File.read(file_data.path).encode('utf-8')
      if csv
        csv    = CSV::parse(csv)
        fields = csv.shift
        fields = fields.map { |f| f.downcase.gsub(' ', '_') }
        fields = fields.map { |f| f.gsub("\xEF\xBB\xBF", '') }
        csv    = csv.collect { |record| Hash[*fields.zip(record).flatten ] }
      else
        csv
      end
    rescue => e
      csv = false
      #raise e #unless Rails.env.production?
    ensure
      csv
    end
    csv
  end
end
